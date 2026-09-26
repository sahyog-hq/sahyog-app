import 'dart:convert';
import 'dart:typed_data';

/// Shared BLE advertisement contract. No pairing, no GATT session.
class BleDistressProtocol {
  BleDistressProtocol._();

  /// 16-bit BLE UUID in the Bluetooth SIG base.
  static const serviceUuid = '0000ffff-0000-1000-8000-00805f9b34fb';

  /// Company identifier used as manufacturer-data key.
  static const manufacturerId = 0x0ca7;

  static const version = 1;
  static const flagSos = 0x01;
  static const flagCancel = 0x02;

  static const int payloadBytes = 14;
}

class DistressAdvertisement {
  DistressAdvertisement({
    required this.flags,
    required this.uuidHash,
    this.uuid,
    this.latE6,
    this.lngE6,
    this.typeCode = 0,
  });

  final int flags;
  final int uuidHash;
  final String? uuid;
  final int? latE6;
  final int? lngE6;
  final int typeCode;

  bool get isSos => (flags & BleDistressProtocol.flagSos) != 0;
  bool get isCancel => (flags & BleDistressProtocol.flagCancel) != 0;

  double? get lat => latE6 == null || latE6 == 0 ? null : latE6! / 1e6;
  double? get lng => lngE6 == null || lngE6 == 0 ? null : lngE6! / 1e6;

  static int hashUuid(String uuid) {
    final cleaned = uuid.replaceAll('-', '');
    var hash = 0x811c9dc5;
    for (final unit in utf8.encode(cleaned)) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  Uint8List toManufacturerBytes() {
    final data = ByteData(BleDistressProtocol.payloadBytes);
    data.setUint8(0, BleDistressProtocol.version);
    data.setUint8(1, flags);
    data.setUint32(2, uuidHash);
    data.setInt32(6, latE6 ?? 0);
    data.setInt32(10, lngE6 ?? 0);
    return data.buffer.asUint8List();
  }

  static DistressAdvertisement? parse(List<int> bytes) {
    if (bytes.length < BleDistressProtocol.payloadBytes) return null;
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    if (data.getUint8(0) != BleDistressProtocol.version) return null;
    return DistressAdvertisement(
      flags: data.getUint8(1),
      uuidHash: data.getUint32(2),
      latE6: data.getInt32(6),
      lngE6: data.getInt32(10),
    );
  }

  factory DistressAdvertisement.sos({
    required String uuid,
    double? lat,
    double? lng,
  }) {
    return DistressAdvertisement(
      flags: BleDistressProtocol.flagSos,
      uuidHash: hashUuid(uuid),
      uuid: uuid,
      latE6: lat == null ? null : (lat * 1e6).round(),
      lngE6: lng == null ? null : (lng * 1e6).round(),
    );
  }

  factory DistressAdvertisement.cancel({required String uuid}) {
    return DistressAdvertisement(
      flags: BleDistressProtocol.flagCancel,
      uuidHash: hashUuid(uuid),
      uuid: uuid,
    );
  }

  Map<String, dynamic> toJson() => {
        'flags': flags,
        'uuidHash': uuidHash,
        'uuid': uuid,
        'latE6': latE6,
        'lngE6': lngE6,
        'typeCode': typeCode,
      };

  factory DistressAdvertisement.fromJson(Map<String, dynamic> json) {
    return DistressAdvertisement(
      flags: json['flags'] as int? ?? BleDistressProtocol.flagSos,
      uuidHash: json['uuidHash'] as int? ?? 0,
      uuid: json['uuid'] as String?,
      latE6: json['latE6'] as int?,
      lngE6: json['lngE6'] as int?,
      typeCode: json['typeCode'] as int? ?? 0,
    );
  }
}
