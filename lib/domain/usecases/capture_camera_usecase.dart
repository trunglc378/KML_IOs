import '../entities/media_file_entity.dart';
import '../repositories/data_collection_repository.dart';

/// UseCase chup anh bang camera (FR-IO-CAM-01).
///
/// Tang Domain thuan khiet, khong phu thuoc AVFoundation.
class CaptureCameraUseCase {
  const CaptureCameraUseCase(this._repository);

  final DataCollectionRepository _repository;

  Future<MediaFileEntity?> execute() async {
    return _repository.captureCamera();
  }
}
