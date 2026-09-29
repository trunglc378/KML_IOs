import 'entities/device_metadata_entity.dart';

/// Giao dien thu thap thong tin thiet bi.
///
/// Tang Domain thuan khiet, khong import package platform hay storage.
abstract class DeviceCollectorRepository {
  Future<DeviceMetadataEntity> collectDeviceInfo();
  Future<String> getDeviceId();
}
