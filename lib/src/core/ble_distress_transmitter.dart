import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ble_distress_permissions.dart';
import 'ble_distress_protocol.dart';

/// Turns this phone into a BLE peripheral advertiser.
/// One-way broadcast — no pairing, no GATT connection.
/// Payload is persisted so advertising resumes after process death / offline.
class BleDistressTransmitter {
  BleDistressTransmitter._();
  static final BleDistressTransmitter instance = BleDistressTransmitter._();

  static const _storeKey = 'ble_distress_active_v1';

  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();
  DistressAdvertisement? _active;
  bool _advertising = false;

  bool get isAdvertising => _advertising;
  DistressAdvertisement? get active => _active;

  /// Start (or refresh) advertising. Works with airplane-mode data / no internet.
  Future<bool> start(DistressAdvertisement advertisement) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return false;
    final allowed = await BleDistressPermissions.request();
    if (!allowed) return false;

    _active = advertisement;
    await _persist(advertisement);

    try {
      if (await _peripheral.isAdvertising) {
        await _peripheral.stop();
      }
      await _peripheral.start(
        advertiseData: AdvertiseData(
          serviceUuid: BleDistressProtocol.serviceUuid,
          manufacturerId: BleDistressProtocol.manufacturerId,
          manufacturerData: advertisement.toManufacturerBytes(),
          localName: 'SYSOS',
          includeDeviceName: false,
        ),
      );
      _advertising = true;
      debugPrint('[BLE TX] advertising SOS hash=${advertisement.uuidHash}');
      return true;
    } catch (e) {
      _advertising = false;
      debugPrint('[BLE TX] start failed: $e');
      return false;
    }
  }

  Future<void> stop() async {
    _advertising = false;
    _active = null;
    await _clearStore();
    try {
      if (await _peripheral.isAdvertising) {
        await _peripheral.stop();
      }
    } catch (e) {
      debugPrint('[BLE TX] stop failed: $e');
    }
  }

  /// Reload a stored SOS and keep transmitting it (offline resume).
  Future<bool> restorePersisted() async {
    final stored = await _load();
    if (stored == null || stored.isCancel) return false;
    return start(stored);
  }

  Future<void> _persist(DistressAdvertisement advertisement) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, jsonEncode(advertisement.toJson()));
  }

  Future<DistressAdvertisement?> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return DistressAdvertisement.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearStore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storeKey);
  }
}
