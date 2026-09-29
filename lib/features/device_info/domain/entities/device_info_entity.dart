/// Thuc the thong tin thiet bi o tang Domain (SDS v4.0 Muc 8.2).
///
/// Moi ban ghi gan platform = "ios" va deviceId theo quy tac 6.2 so 1.
class DeviceInfoEntity {
  const DeviceInfoEntity({
    this.id,
    required this.deviceId,
    required this.osVersion,
    required this.model,
    required this.networkType,
    required this.collectedAt,
    this.platform = 'ios',
    this.sent = false,
  });

  final int? id;
  final String deviceId;
  final String osVersion;
  final String model;
  final String networkType;
  final String collectedAt;
  final String platform;
  final bool sent;
}
