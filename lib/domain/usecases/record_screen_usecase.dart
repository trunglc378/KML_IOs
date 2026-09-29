import '../entities/media_file_entity.dart';
import '../repositories/data_collection_repository.dart';

/// UseCase ghi man hinh (FR-IO-SCR-01).
///
/// Tang Domain thuan khiet, khong phu thuoc ReplayKit.
class RecordScreenUseCase {
  const RecordScreenUseCase(this._repository);

  final DataCollectionRepository _repository;

  Future<MediaFileEntity?> execute({int durationSeconds = 10}) async {
    return _repository.recordScreen(durationSeconds: durationSeconds);
  }
}
