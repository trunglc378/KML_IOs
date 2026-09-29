/// Thuc the mau vi tri o tang Domain (SDS v4.0 Muc 8.2).
///
/// Moi ban ghi gan platform = "ios" va deviceId theo quy tac 6.2 so 1.
class LocationEntity {
  const LocationEntity({
    this.id,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.altitude,
    required this.speed,
    required this.bearing,
    required this.collectedAt,
    this.platform = 'ios',
    this.sent = false,
  });

  final int? id;
  final String deviceId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double bearing;
  final String collectedAt;
  final String platform;
  final bool sent;
}
