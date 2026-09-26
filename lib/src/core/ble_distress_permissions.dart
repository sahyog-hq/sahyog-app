import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runtime BLE permissions for unpaired advertise + scan.
///
/// Android 12+ (API 31):
///   BLUETOOTH_SCAN, BLUETOOTH_ADVERTISE, BLUETOOTH_CONNECT, ACCESS_FINE_LOCATION
/// Android ≤ 11:
///   BLUETOOTH, BLUETOOTH_ADMIN, ACCESS_FINE_LOCATION
/// iOS:
///   NSBluetoothAlwaysUsageDescription, NSBluetoothPeripheralUsageDescription,
///   NSLocationWhenInUseUsageDescription (Info.plist)
class BleDistressPermissions {
  BleDistressPermissions._();

  static Future<bool> request() async {
    if (kIsWeb) return false;
    if (!(Platform.isAndroid || Platform.isIOS)) return false;

    final wanted = <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetooth,
      Permission.locationWhenInUse,
      Permission.location,
    ];

    final statuses = await wanted.request();
    final scanOk = _granted(statuses[Permission.bluetoothScan]) ||
        _granted(statuses[Permission.bluetooth]);
    final advertiseOk = _granted(statuses[Permission.bluetoothAdvertise]) ||
        _granted(statuses[Permission.bluetooth]);
    final locationOk = _granted(statuses[Permission.locationWhenInUse]) ||
        _granted(statuses[Permission.location]);

    final ok = scanOk && advertiseOk && locationOk;
    if (!ok) {
      debugPrint('[BLE] permissions incomplete: $statuses');
    }
    return ok;
  }

  static bool _granted(PermissionStatus? status) {
    if (status == null) return false;
    return status.isGranted || status.isLimited;
  }
}
