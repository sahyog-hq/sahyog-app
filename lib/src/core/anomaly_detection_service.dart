import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

enum TinyMLSensitivity { testing, production }

enum AnomalyType {
  freefallImpact,
  manDownImmobility,
  highImpactCrash,
  panicShake,
}

enum SosTimerState { idle, running, cancelled, expired }

class AnomalyEvent {
  AnomalyEvent({
    required this.type,
    required this.title,
    required this.description,
    required this.detectedValue,
    this.probability = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final AnomalyType type;
  final String title;
  final String description;
  final double detectedValue;
  final double probability;
  final DateTime timestamp;
}

/// Circular sliding window of accelerometer frames for a TFLite model.
class AccelWindow {
  AccelWindow({this.size = 50}) : _data = Float32List(size * 3);

  static const int channels = 3;
  final int size;
  final Float32List _data;
  int _write = 0;
  int _count = 0;

  bool get isReady => _count == size;

  void clear() {
    _write = 0;
    _count = 0;
    _data.fillRange(0, _data.length, 0);
  }

  void push(double x, double y, double z) {
    final i = _write * channels;
    _data[i] = x;
    _data[i + 1] = y;
    _data[i + 2] = z;
    _write = (_write + 1) % size;
    if (_count < size) _count++;
  }

  /// Chronological `[size * 3]` copy, oldest sample first.
  Float32List copyChronological() {
    final out = Float32List(size * channels);
    if (_count == 0) return out;
    final start = _count == size ? _write : 0;
    for (var i = 0; i < _count; i++) {
      final src = ((start + i) % size) * channels;
      final dst = i * channels;
      out[dst] = _data[src];
      out[dst + 1] = _data[src + 1];
      out[dst + 2] = _data[src + 2];
    }
    return out;
  }

  /// Nested tensor `[1, size, 3]` with values in g (÷ 9.81).
  List<List<List<double>>> asModelInput({double gravity = 9.81}) {
    final chrono = copyChronological();
    final frames = <List<double>>[];
    for (var i = 0; i < size; i++) {
      final o = i * channels;
      frames.add([
        chrono[o] / gravity,
        chrono[o + 1] / gravity,
        chrono[o + 2] / gravity,
      ]);
    }
    return [frames];
  }
}

/// Streams accelerometer data, runs a sliding window through TFLite (or a
/// heuristic stand-in), and owns the 10s auto-SOS countdown.
class AnomalyDetectionService {
  AnomalyDetectionService._();
  static final AnomalyDetectionService instance = AnomalyDetectionService._();

  static const int windowSize = 50;
  static const double anomalyThreshold = 0.85;
  static const int sosCountdownSeconds = 10;
  static const String modelAsset = 'assets/models/anomaly_detector.tflite';

  final AccelWindow _window = AccelWindow(size: windowSize);
  StreamSubscription<AccelerometerEvent>? _accelSub;
  Interpreter? _interpreter;
  Timer? _sosTimer;
  int _inferStride = 0;

  bool _isEnabled = true;
  bool _disposed = false;
  TinyMLSensitivity _sensitivity = TinyMLSensitivity.testing;
  DateTime? _lastTriggerTime;
  AnomalyEvent? _lastEvent;

  void Function(AnomalyEvent event)? onAnomalyDetected;
  VoidCallback? onSOSTimerExpired;

  final ValueNotifier<int> countdownSeconds = ValueNotifier<int>(0);
  final ValueNotifier<SosTimerState> timerState =
      ValueNotifier<SosTimerState>(SosTimerState.idle);

  bool get isEnabled => _isEnabled;
  bool get usingTflite => _interpreter != null;
  bool get alertOpen =>
      timerState.value == SosTimerState.running || _lastEvent != null;
  TinyMLSensitivity get sensitivity => _sensitivity;
  AnomalyEvent? get lastEvent => _lastEvent;
  double lastProbability = 0;

  Future<void> start() async {
    if (_disposed) return;
    await loadModel();
    _subscribe();
  }

  Future<void> loadModel() async {
    if (_interpreter != null) return;
    try {
      _interpreter = await Interpreter.fromAsset(modelAsset);
      debugPrint(
        '[TinyML] TFLite loaded. in=${_interpreter!.getInputTensor(0).shape} '
        'out=${_interpreter!.getOutputTensor(0).shape}',
      );
    } catch (e) {
      _interpreter = null;
      debugPrint('[TinyML] No TFLite model ($e). Using heuristic scorer.');
    }
  }

  void _subscribe() {
    if (_accelSub != null) return;
    _accelSub = accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(
      _onAccelerometer,
      onError: (Object err) {
        debugPrint('[TinyML] Sensor stream error: $err');
      },
      cancelOnError: false,
    );
    debugPrint('[TinyML] accelerometerEventStream subscribed');
  }

  void stop() {
    _accelSub?.cancel();
    _accelSub = null;
    _window.clear();
    cancelSOSTimer();
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (enabled) {
      start();
    } else {
      stop();
    }
  }

  void setSensitivity(TinyMLSensitivity mode) {
    _sensitivity = mode;
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (!_isEnabled || _disposed) return;
    _window.push(event.x, event.y, event.z);
    if (!_window.isReady) return;
    if (timerState.value == SosTimerState.running) return;

    _inferStride = (_inferStride + 1) % 8;
    if (_inferStride != 0) return;

    final quiet = _sensitivity == TinyMLSensitivity.testing ? 8 : 30;
    if (_lastTriggerTime != null &&
        DateTime.now().difference(_lastTriggerTime!).inSeconds < quiet) {
      return;
    }

    final score = _runInference();
    lastProbability = score;
    if (score <= anomalyThreshold) return;

    final eventInfo = _classifyWindow(_window.copyChronological(), score);
    _lastEvent = eventInfo;
    debugPrint('[TinyML] anomaly p=${score.toStringAsFixed(3)} ${eventInfo.type}');
    activateSOSTimer();
    onAnomalyDetected?.call(eventInfo);
  }

  double _runInference() {
    final interpreter = _interpreter;
    if (interpreter == null) {
      return _heuristicProbability(_window.copyChronological());
    }
    try {
      final input = _window.asModelInput();
      final output = List.generate(1, (_) => List<double>.filled(1, 0));
      interpreter.run(input, output);
      final raw = output[0][0];
      if (raw.isNaN || raw.isInfinite) return 0;
      return raw.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('[TinyML] Interpreter.run failed: $e');
      return _heuristicProbability(_window.copyChronological());
    }
  }

  double _heuristicProbability(Float32List chrono) {
    var maxMag = 0.0;
    var minMag = 100.0;
    var sum = 0.0;
    var lowCount = 0;
    var hadFreefall = false;
    final n = windowSize;
    final isTesting = _sensitivity == TinyMLSensitivity.testing;
    final freeThresh = isTesting ? 4.5 : 2.0;
    final crashThresh = isTesting ? 18.0 : 32.0;
    final impactThresh = isTesting ? 14.0 : 25.0;

    for (var i = 0; i < n; i++) {
      final o = i * AccelWindow.channels;
      final mag = sqrt(
        chrono[o] * chrono[o] +
            chrono[o + 1] * chrono[o + 1] +
            chrono[o + 2] * chrono[o + 2],
      );
      maxMag = max(maxMag, mag);
      minMag = min(minMag, mag);
      sum += mag;
      if (mag < freeThresh) {
        lowCount++;
        if (lowCount >= (isTesting ? 3 : 6)) hadFreefall = true;
      } else {
        lowCount = 0;
      }
    }
    final mean = sum / n;
    var varSum = 0.0;
    for (var i = 0; i < n; i++) {
      final o = i * AccelWindow.channels;
      final mag = sqrt(
        chrono[o] * chrono[o] +
            chrono[o + 1] * chrono[o + 1] +
            chrono[o + 2] * chrono[o + 2],
      );
      varSum += pow(mag - mean, 2).toDouble();
    }
    final std = sqrt(varSum / n);

    if (hadFreefall && maxMag > impactThresh) return 0.96;
    if (maxMag > crashThresh) return 0.93;
    if (std > (isTesting ? 8 : 12) && maxMag > impactThresh) return 0.88;
    if (maxMag > impactThresh && std < (isTesting ? 0.5 : 0.15)) return 0.86;
    return (maxMag / 40).clamp(0.0, 0.7);
  }

  AnomalyEvent _classifyWindow(Float32List chrono, double probability) {
    var maxMag = 0.0;
    var minMag = 100.0;
    for (var i = 0; i < windowSize; i++) {
      final o = i * AccelWindow.channels;
      final mag = sqrt(
        chrono[o] * chrono[o] +
            chrono[o + 1] * chrono[o + 1] +
            chrono[o + 2] * chrono[o + 2],
      );
      maxMag = max(maxMag, mag);
      minMag = min(minMag, mag);
    }
    if (minMag < 3 && maxMag > 12) {
      return AnomalyEvent(
        type: AnomalyType.freefallImpact,
        title: 'Freefall & impact detected',
        description:
            'Weightlessness then a hard hit (${maxMag.toStringAsFixed(1)} m/s²). p=${probability.toStringAsFixed(2)}',
        detectedValue: maxMag,
        probability: probability,
      );
    }
    if (maxMag > 28) {
      return AnomalyEvent(
        type: AnomalyType.highImpactCrash,
        title: 'High-impact crash detected',
        description:
            'Severe acceleration (${maxMag.toStringAsFixed(1)} m/s²). p=${probability.toStringAsFixed(2)}',
        detectedValue: maxMag,
        probability: probability,
      );
    }
    return AnomalyEvent(
      type: AnomalyType.panicShake,
      title: 'Unusual physical activity detected',
      description:
          'On-device model score ${probability.toStringAsFixed(2)} exceeded $anomalyThreshold.',
      detectedValue: maxMag,
      probability: probability,
    );
  }

  /// Starts a 10s visual countdown. Cancel with [cancelSOSTimer].
  void activateSOSTimer() {
    cancelSOSTimer();
    _lastTriggerTime = DateTime.now();
    countdownSeconds.value = sosCountdownSeconds;
    timerState.value = SosTimerState.running;
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final next = countdownSeconds.value - 1;
      countdownSeconds.value = next < 0 ? 0 : next;
      if (next > 0) return;
      timer.cancel();
      _sosTimer = null;
      timerState.value = SosTimerState.expired;
      onSOSTimerExpired?.call();
    });
  }

  void cancelSOSTimer() {
    _sosTimer?.cancel();
    _sosTimer = null;
    if (timerState.value == SosTimerState.running) {
      timerState.value = SosTimerState.cancelled;
    }
    countdownSeconds.value = 0;
  }

  void finishAlert() {
    if (timerState.value == SosTimerState.running) {
      cancelSOSTimer();
    }
    if (timerState.value != SosTimerState.idle) {
      timerState.value = SosTimerState.idle;
    }
    _lastEvent = null;
    _lastTriggerTime = DateTime.now();
  }

  void simulateAnomaly(AnomalyType type) {
    final event = switch (type) {
      AnomalyType.freefallImpact => AnomalyEvent(
        type: type,
        title: 'Simulated freefall & drop',
        description: 'Forced anomaly for testing. p=0.99',
        detectedValue: 18.5,
        probability: 0.99,
      ),
      AnomalyType.manDownImmobility => AnomalyEvent(
        type: type,
        title: 'Simulated man-down alert',
        description: 'Forced anomaly for testing. p=0.99',
        detectedValue: 0.05,
        probability: 0.99,
      ),
      AnomalyType.highImpactCrash => AnomalyEvent(
        type: type,
        title: 'Simulated high-impact crash',
        description: 'Forced anomaly for testing. p=0.99',
        detectedValue: 28.2,
        probability: 0.99,
      ),
      AnomalyType.panicShake => AnomalyEvent(
        type: type,
        title: 'Simulated panic shake',
        description: 'Forced anomaly for testing. p=0.99',
        detectedValue: 15.0,
        probability: 0.99,
      ),
    };
    lastProbability = event.probability;
    _lastEvent = event;
    activateSOSTimer();
    onAnomalyDetected?.call(event);
  }

  void dispose() {
    _disposed = true;
    stop();
    _interpreter?.close();
    _interpreter = null;
    countdownSeconds.dispose();
    timerState.dispose();
  }
}
