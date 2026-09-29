import 'entities/photo_entry_entity.dart';

/// Giao dien thu thap metadata thu vien anh tren thiet bi.
abstract class PhotosCollectorRepository {
  Future<bool> checkPermission();
  Future<bool> requestPermission();
  Future<List<PhotoEntryEntity>> fetchRecentPhotos({int limit = 20});
}
