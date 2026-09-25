import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum TinyMLSensitivity {
  testing,
  production,
}

enum AnomalyType {
  freefallImpact,
  manDownImmobility,
  highImpactCrash,
  panicShake,
}

class AnomalyEvent {
  final AnomalyType type;
  final String title;
  final String description;
  final double detectedValue;
  final DateTime timestamp;

  AnomalyEvent({
    required this.type,
    required this.title,
    required this.description,
    required this.detectedValue,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// TinyML On-Device Sensor Monitoring Engine
/// Analyzes real-time accelerometer streams to detect emergency anomalies
class TinyMLSensorService {
  static final TinyMLSensorService instance = TinyMLSensorService._internal();
  TinyMLSensorService._internal();

  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  
  bool _isEnabled = true;
  TinyMLSensitivity _sensitivity = TinyMLSensitivity.testing; // Default to testing for easy evaluation
  
  // Callback when an anomaly is detected
  void Function(AnomalyEvent event)? onAnomalyDetected;

  // Sliding window for acceleration magnitude history (samples)
  final List<double> _window = [];
  static const int _maxWindowSize = 30; // ~1.5 seconds of data at 20Hz

  // State flags for composite anomaly detection (e.g. Immobility after impact)
  DateTime? _lastImpactTime;
  DateTime? _lastShakeTime;
  int _shakeCount = 0;
  DateTime? _lastTriggerTime; // Cooldown timer to prevent alert spamming

  bool get isEnabled => _isEnabled;
  TinyMLSensitivity get sensitivity => _sensitivity;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (_isEnabled) {
      startMonitoring();
    } else {
      stopMonitoring();
    }
  }

  void setSensitivity(TinyMLSensitivity mode) {
    _sensitivity = mode;
    debugPrint('[TinyML] Sensitivity set to: ${_sensitivity.name}');
  }

  void startMonitoring() {
    if (_accelSub != null) return;

    try {
      _accelSub = userAccelerometerEventStream().listen(
        _processAccelerometerData,
        onError: (err) {
          debugPrint('[TinyML] Sensor stream error: $err');
        },
        cancelOnError: false,
      );
      debugPrint('[TinyML] Real-time Sensor Monitoring Started (Mode: ${_sensitivity.name})');
    } catch (e) {
      debugPrint('[TinyML] Failed to start sensor stream: $e');
    }
  }

  void stopMonitoring() {
    _accelSub?.cancel();
    _accelSub = null;
    _window.clear();
    debugPrint('[TinyML] Real-time Sensor Monitoring Stopped');
  }

  void _processAccelerometerData(UserAccelerometerEvent event) {
    if (!_isEnabled) return;

    // Calculate total linear acceleration magnitude: |a| = sqrt(x^2 + y^2 + z^2)
    final double g = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    _window.add(g);
    if (_window.length > _maxWindowSize) {
      _window.removeAt(0);
    }

    if (_window.length < 5) return;

    // Cooldown check (5 seconds between triggers)
    if (_lastTriggerTime != null &&
        DateTime.now().difference(_lastTriggerTime!).inSeconds < 5) {
      return;
    }

    // Thresholds based on selected mode
    final isTesting = _sensitivity == TinyMLSensitivity.testing;
    
    final double freefallLowThreshold = isTesting ? 4.5 : 2.5;
    final double impactThreshold = isTesting ? 12.0 : 20.0;
    final double crashThreshold = isTesting ? 14.0 : 25.0;
    final double stillnessVarianceThreshold = isTesting ? 0.4 : 0.2;
    final int immobilitySeconds = isTesting ? 5 : 12;

    // ----------------------------------------------------
    // 1. Freefall + Impact (Phone dropping or building collapse)
    // ----------------------------------------------------
    int consecutiveLowG = 0;
    bool hadFreefall = false;
    final int requiredFreefallSamples = isTesting ? 3 : 5;
    
    // Check all values in the window except the very latest ones which might be the impact
    final int checkLength = max(0, _window.length - 2);
    for (int i = 0; i < checkLength; i++) {
      if (_window[i] < freefallLowThreshold) {
        consecutiveLowG++;
        if (consecutiveLowG >= requiredFreefallSamples) {
          hadFreefall = true;
          break;
        }
      } else {
        consecutiveLowG = 0;
      }
    }

    if (hadFreefall && g > impactThreshold) {
      _triggerAnomaly(AnomalyEvent(
        type: AnomalyType.freefallImpact,
        title: '🪂 Freefall & Severe Drop Detected',
        description: 'Freefall weightlessness followed by heavy impact (${g.toStringAsFixed(1)} m/s²).',
        detectedValue: g,
      ));
      return;
    }

    // ----------------------------------------------------
    // 2. Panic Shake Gesture
    // ----------------------------------------------------
    final shakeThreshold = isTesting ? 12.0 : 16.0;
    if (g > shakeThreshold) {
      final now = DateTime.now();
      if (_lastShakeTime == null || now.difference(_lastShakeTime!).inMilliseconds > 1500) {
        _shakeCount = 1;
      } else if (now.difference(_lastShakeTime!).inMilliseconds > 150) {
        // Only count distinct shake strokes (debounce a little)
        _shakeCount++;
      }
      _lastShakeTime = now;

      if (_shakeCount >= (isTesting ? 3 : 4)) {
        _shakeCount = 0;
        _triggerAnomaly(AnomalyEvent(
          type: AnomalyType.panicShake,
          title: '🚨 Panic Shake Gesture Detected',
          description: 'Rapid distress shake pattern detected from motion sensors.',
          detectedValue: g,
        ));
        return;
      }
      
      // If we are actively shaking (shake count > 1) and we haven't timed out, 
      // we might want to skip Crash detection for this specific reading to avoid false crash from a hard shake.
      if (_shakeCount > 1 && now.difference(_lastShakeTime!).inMilliseconds < 1000) {
        return; 
      }
    }

    // ----------------------------------------------------
    // 3. High Impact / Crash Detection
    // ----------------------------------------------------
    if (g > crashThreshold) {
      _triggerAnomaly(AnomalyEvent(
        type: AnomalyType.highImpactCrash,
        title: '💥 High Impact / Crash Detected',
        description: 'Severe impact force (${g.toStringAsFixed(1)} m/s²) measured by motion sensors.',
        detectedValue: g,
      ));
      return;
    }

    // Track impacts for Immobility check
    if (g > impactThreshold / 1.5) {
      _lastImpactTime = DateTime.now();
    }

    // ----------------------------------------------------
    // 4. Man-Down / Immobility (Victim unconscious/trapped)
    // ----------------------------------------------------
    if (_lastImpactTime != null) {
      final elapsed = DateTime.now().difference(_lastImpactTime!).inSeconds;
      if (elapsed >= immobilitySeconds) {
        // Calculate variance of last 10 samples
        final double avg = _window.reduce((a, b) => a + b) / _window.length;
        final double variance = sqrt(_window.map((x) => pow(x - avg, 2)).reduce((a, b) => a + b) / _window.length);

        if (variance < stillnessVarianceThreshold) {
          _lastImpactTime = null; // Reset
          _triggerAnomaly(AnomalyEvent(
            type: AnomalyType.manDownImmobility,
            title: '🧍 Man-Down / Immobility Alert',
            description: 'No movement detected for $immobilitySeconds seconds following a physical shock.',
            detectedValue: variance,
          ));
          return;
        }
      }
    }
  }

  void _triggerAnomaly(AnomalyEvent event) {
    _lastTriggerTime = DateTime.now();
    debugPrint('[TinyML ANOMALY TRIGGERED] ${event.title}: ${event.description}');
    if (onAnomalyDetected != null) {
      onAnomalyDetected!(event);
    }
  }

  /// Helper method for manual testing trigger
  void simulateAnomaly(AnomalyType type) {
    switch (type) {
      case AnomalyType.freefallImpact:
        _triggerAnomaly(AnomalyEvent(
          type: type,
          title: '🪂 Simulated Freefall & Drop',
          description: 'Simulated drop anomaly for testing.',
          detectedValue: 18.5,
        ));
        break;
      case AnomalyType.manDownImmobility:
        _triggerAnomaly(AnomalyEvent(
          type: type,
          title: '🧍 Simulated Man-Down Alert',
          description: 'Simulated immobility under debris.',
          detectedValue: 0.05,
        ));
        break;
      case AnomalyType.highImpactCrash:
        _triggerAnomaly(AnomalyEvent(
          type: type,
          title: '💥 Simulated High-Impact Crash',
          description: 'Simulated structural collapse / collision.',
          detectedValue: 28.2,
        ));
        break;
      case AnomalyType.panicShake:
        _triggerAnomaly(AnomalyEvent(
          type: type,
          title: '🚨 Simulated Panic Shake',
          description: 'Simulated distress shake gesture.',
          detectedValue: 15.0,
        ));
        break;
    }
  }
}
