import '../../features/device_info/domain/entities/device_info_entity.dart';
import '../repositories/data_collection_repository.dart';

/// UseCase lay thong tin thiet bi va mang (FR-IO-DEV-01).
///
/// Tang Domain thuan khiet, khong import Flutter hay package ha tang mang.
class GetDeviceInfoUseCase {
  const GetDeviceInfoUseCase(this._repository);

  final DataCollectionRepository _repository;

  Future<DeviceInfoEntity> execute() async {
    return _repository.getDeviceInfo();
  }
}
