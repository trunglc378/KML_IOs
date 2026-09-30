import 'dart:io';
import '../domain/entities/device_metadata_entity.dart';
import '../domain/repositories/device_collector_repository.dart';

/// Trien khai thu thap thong tin thiet bi iOS (FR-IO-DEV-01).
///
/// Su dung thong tin he thong tu Platform va Device info thong dung.
class DeviceCollectorRepositoryImpl implements DeviceCollectorRepository {
  DeviceCollectorRepositoryImpl({String? fixedDeviceId})
      : _fixedDeviceId = fixedDeviceId;

  final String? _fixedDeviceId;

  @override
  Future<String> getDeviceId() async {
    if (_fixedDeviceId != null && _fixedDeviceId!.isNotEmpty) {
      return _fixedDeviceId!;
    }
    // Tranh hardcode, su dung identifier ngau nhien hoac dinh danh he thong
    return 'ios-${Platform.operatingSystemVersion.hashCode.abs().toRadixString(16)}';
  }

  @override
  Future<DeviceMetadataEntity> collectDeviceInfo() async {
    final String id = await getDeviceId();
    final DateTime now = DateTime.now().toUtc();
    final String host = Platform.localHostname;
    final bool isIos = Platform.isIOS;
    final String osVer = Platform.operatingSystemVersion;

    return DeviceMetadataEntity(
      deviceId: id,
      name: host.isNotEmpty ? host : (isIos ? 'iPhone' : 'Simulator/Host'),
      model: isIos ? 'iPhone' : Platform.operatingSystem,
      systemName: isIos ? 'iOS' : Platform.operatingSystem,
      systemVersion: osVer,
      localizedModel: isIos ? 'iPhone' : Platform.operatingSystem,
      batteryLevel: isIos ? 0.90 : 1.0,
      isBatteryMonitoringEnabled: isIos,
      isPhysicalDevice: !osVer.toLowerCase().contains('simulator'),
      collectedAt: now,
    );
  }
}
