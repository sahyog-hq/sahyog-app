import 'package:flutter/foundation.dart';

import 'ble_distress_protocol.dart';
import 'ble_distress_receiver.dart';
import 'ble_distress_transmitter.dart';
import 'local_notification_service.dart';
import 'socket_service.dart';

/// Offline "one transmits, everyone receives" BLE SOS.
/// Advertising is persisted locally and continues without internet.
class BleDistressHub {
  BleDistressHub._() {
    _receiver.onNearbyDisasterDetected = (deviceId, rssi) {
      onNearbyDisasterDetected?.call(deviceId, rssi);
    };
    _receiver.onPacket = _handlePacket;
  }

  static final BleDistressHub instance = BleDistressHub._();

  final BleDistressTransmitter _transmitter = BleDistressTransmitter.instance;
  final BleDistressReceiver _receiver = BleDistressReceiver.instance;

  NearbyDisasterCallback? onNearbyDisasterDetected;

  bool get isAdvertising => _transmitter.isAdvertising;
  bool get isScanning => _receiver.isScanning;

  Future<void> startListening() => _receiver.start();

  Future<void> stopListening() => _receiver.stop();

  Future<bool> broadcastSos({
    required String uuid,
    double? lat,
    double? lng,
    String? type,
  }) {
    final packet = DistressAdvertisement.sos(uuid: uuid, lat: lat, lng: lng);
    return _transmitter.start(packet);
  }

  Future<void> stopBroadcast() => _transmitter.stop();

  Future<bool> restorePersistedBroadcast() => _transmitter.restorePersisted();

  void _handlePacket(
    String deviceId,
    int rssi,
    DistressAdvertisement? packet,
  ) {
    debugPrint('[BLE] nearby $deviceId rssi=$rssi cancel=${packet?.isCancel}');
    if (packet?.isCancel == true) {
      final hash = packet!.uuidHash.toString();
      final current = Map<String, Map<String, dynamic>>.from(
        SocketService.instance.liveSosAlerts.value,
      );
      current.removeWhere(
        (key, value) =>
            key == hash ||
            value['uuid_hash'] == packet.uuidHash ||
            value['ble_device_id'] == deviceId,
      );
      SocketService.instance.liveSosAlerts.value = current;
      return;
    }

    final id = packet?.uuid ?? deviceId;
    final current = Map<String, Map<String, dynamic>>.from(
      SocketService.instance.liveSosAlerts.value,
    );
    current[id] = {
      'uuid': id,
      'uuid_hash': packet?.uuidHash,
      'type': 'Emergency',
      'lat': packet?.lat,
      'lng': packet?.lng,
      'rssi': rssi,
      'ble_device_id': deviceId,
      'source': 'ble_advertisement',
      'relayed_via_mesh': true,
      'offline': true,
    };
    SocketService.instance.liveSosAlerts.value = current;

    LocalNotificationService.instance.showMeshSosNotification(
      title: 'SOS nearby (BLE)',
      body: 'Distress beacon $rssi dBm. No internet required.',
      payload: id,
    );
  }
}
