import 'entities/location_entity.dart';

/// Giao dien thu thap toa do vi tri GPS.
///
/// Tang Domain thuan khiet, khong phu thuoc platform hay sensor ngoai.
abstract class LocationCollectorRepository {
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<LocationEntity?> getCurrentLocation();
  Stream<LocationEntity> get continuousLocationStream;
}
