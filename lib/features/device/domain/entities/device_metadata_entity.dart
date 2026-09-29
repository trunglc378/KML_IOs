/// Thuc the thong tin thiet bi thu thap duoc (FR-IO-DEV-01).
///
/// Tang Domain thuan khiet, khong phu thuoc platform hay package ngoai.
class DeviceMetadataEntity {
  const DeviceMetadataEntity({
    required this.deviceId,
    required this.name,
    required this.model,
    required this.systemName,
    required this.systemVersion,
    required this.localizedModel,
    required this.batteryLevel,
    required this.isBatteryMonitoringEnabled,
    required this.isPhysicalDevice,
    required this.collectedAt,
  });

  final String deviceId;
  final String name;
  final String model;
  final String systemName;
  final String systemVersion;
  final String localizedModel;
  final double batteryLevel;
  final bool isBatteryMonitoringEnabled;
  final bool isPhysicalDevice;
  final DateTime collectedAt;

  /// Chuyen doi sang dinh dang DTO dong van ban chuan (SDS Muc 6.5)
  List<String> toRecordLines() {
    return <String>[
      'model=$model localized=$localizedModel',
      'system=$systemName $systemVersion',
      'battery=${(batteryLevel * 100).toStringAsFixed(1)}%',
      'physical=$isPhysicalDevice collected=${collectedAt.toUtc().toIso8601String()}',
    ];
  }
}
