import '../entities/media_file_entity.dart';
import '../repositories/data_collection_repository.dart';

/// UseCase lay danh sach anh tu thu vien (FR-IO-PHO-01).
///
/// Tang Domain thuan khiet, khong phu thuoc Photos framework.
class GetPhotosUseCase {
  const GetPhotosUseCase(this._repository);

  final DataCollectionRepository _repository;

  Future<List<MediaFileEntity>> execute() async {
    return _repository.getPhotos();
  }
}
