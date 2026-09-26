import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ble_distress_permissions.dart';
import 'ble_distress_protocol.dart';

typedef NearbyDisasterCallback = void Function(
  String deviceId,
  int signalStrength,
);

/// Continuous BLE central scanner. No pairing — advertisement packets only.
class BleDistressReceiver {
  BleDistressReceiver._();
  static final BleDistressReceiver instance = BleDistressReceiver._();

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  Timer? _restartTimer;
  final Map<String, DateTime> _lastEmit = {};
  bool _scanning = false;
  bool _wantScan = false;

  NearbyDisasterCallback? onNearbyDisasterDetected;
  void Function(String deviceId, int rssi, DistressAdvertisement? packet)?
      onPacket;

  bool get isScanning => _scanning;

  Future<bool> start() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return false;
    _wantScan = true;
    final allowed = await BleDistressPermissions.request();
    if (!allowed) return false;

    _adapterSub ??= FlutterBluePlus.adapterState.listen((state) {
      if (!_wantScan) return;
      if (state == BluetoothAdapterState.on) {
        _beginScan();
      } else {
        _scanning = false;
      }
    });

    if (FlutterBluePlus.adapterStateNow != BluetoothAdapterState.on) {
      if (Platform.isAndroid) {
        try {
          await FlutterBluePlus.turnOn();
        } catch (e) {
          debugPrint('[BLE RX] turnOn failed: $e');
        }
      }
    }

    return _beginScan();
  }

  Future<bool> _beginScan() async {
    if (!_wantScan) return false;
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
      await _scanSub?.cancel();
      _scanSub = FlutterBluePlus.onScanResults.listen(
        _onResults,
        onError: (Object e) => debugPrint('[BLE RX] scan error: $e'),
      );

      await FlutterBluePlus.startScan(
        withServices: [Guid(BleDistressProtocol.serviceUuid)],
        withMsd: [
          MsdFilter(BleDistressProtocol.manufacturerId),
        ],
        continuousUpdates: true,
        androidUsesFineLocation: true,
      );
      _scanning = true;
      _restartTimer?.cancel();
      _restartTimer = Timer.periodic(const Duration(seconds: 28), (_) {
        if (_wantScan && !FlutterBluePlus.isScanningNow) {
          _beginScan();
        }
      });
      debugPrint('[BLE RX] scanning for ${BleDistressProtocol.serviceUuid}');
      return true;
    } catch (e) {
      _scanning = false;
      debugPrint('[BLE RX] startScan failed: $e');
      return false;
    }
  }

  void _onResults(List<ScanResult> results) {
    for (final result in results) {
      if (!_isDistress(result)) continue;
      final deviceId = result.device.remoteId.str;
      final rssi = result.rssi;
      final now = DateTime.now();
      final previous = _lastEmit[deviceId];
      if (previous != null && now.difference(previous).inMilliseconds < 1500) {
        continue;
      }
      _lastEmit[deviceId] = now;

      final packet = _decode(result);
      onPacket?.call(deviceId, rssi, packet);
      onNearbyDisasterDetected?.call(deviceId, rssi);
    }
  }

  bool _isDistress(ScanResult result) {
    final adv = result.advertisementData;
    final hasService = adv.serviceUuids.any(
      (guid) => guid.str.toLowerCase() == BleDistressProtocol.serviceUuid,
    );
    final hasMsd = adv.manufacturerData.containsKey(
      BleDistressProtocol.manufacturerId,
    );
    final named = adv.advName.toUpperCase().startsWith('SYSOS');
    return hasService || hasMsd || named;
  }

  DistressAdvertisement? _decode(ScanResult result) {
    final bytes =
        result.advertisementData.manufacturerData[BleDistressProtocol.manufacturerId];
    if (bytes == null) return null;
    return DistressAdvertisement.parse(bytes);
  }

  Future<void> stop() async {
    _wantScan = false;
    _scanning = false;
    _restartTimer?.cancel();
    _restartTimer = null;
    await _scanSub?.cancel();
    _scanSub = null;
    await _adapterSub?.cancel();
    _adapterSub = null;
    try {
      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }
    } catch (_) {}
  }
}
