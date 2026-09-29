import '../entities/media_file_entity.dart';
import '../repositories/data_collection_repository.dart';

/// UseCase ghi am microphone (FR-IO-MIC-01).
///
/// Tang Domain thuan khiet, khong phu thuoc AVAudioRecorder.
class RecordMicrophoneUseCase {
  const RecordMicrophoneUseCase(this._repository);

  final DataCollectionRepository _repository;

  Future<MediaFileEntity?> execute({int durationSeconds = 10}) async {
    return _repository.recordMicrophone(durationSeconds: durationSeconds);
  }
}
