import '../../features/location/domain/entities/location_entity.dart';
import '../repositories/data_collection_repository.dart';

/// UseCase thu thap vi tri GPS (FR-IO-LOC-01 / FR-IO-LOC-02).
///
/// Tang Domain thuan khiet, khong import Geolocator hay CLLocationManager.
class GetLocationUseCase {
  const GetLocationUseCase(this._repository);

  final DataCollectionRepository _repository;

  Future<LocationEntity> execute() async {
    return _repository.getLocation();
  }
}
