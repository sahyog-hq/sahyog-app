import 'package:flutter/foundation.dart';

import 'anomaly_detection_service.dart';

export 'anomaly_detection_service.dart';

/// Compatibility facade. Motion inference lives in [AnomalyDetectionService].
class TinyMLSensorService {
  TinyMLSensorService._();
  static final TinyMLSensorService instance = TinyMLSensorService._();

  AnomalyDetectionService get _engine => AnomalyDetectionService.instance;

  bool get isEnabled => _engine.isEnabled;
  bool get alertOpen => _engine.alertOpen;
  TinyMLSensitivity get sensitivity => _engine.sensitivity;

  void Function(AnomalyEvent event)? get onAnomalyDetected =>
      _engine.onAnomalyDetected;

  set onAnomalyDetected(void Function(AnomalyEvent event)? cb) {
    _engine.onAnomalyDetected = cb;
  }

  VoidCallback? get onSOSTimerExpired => _engine.onSOSTimerExpired;

  set onSOSTimerExpired(VoidCallback? cb) {
    _engine.onSOSTimerExpired = cb;
  }

  void finishAlert() => _engine.finishAlert();

  void setEnabled(bool enabled) => _engine.setEnabled(enabled);

  void setSensitivity(TinyMLSensitivity mode) => _engine.setSensitivity(mode);

  void startMonitoring() {
    _engine.start();
  }

  void stopMonitoring() => _engine.stop();

  void simulateAnomaly(AnomalyType type) => _engine.simulateAnomaly(type);
}
