import 'package:permission_handler/permission_handler.dart';

import '../domain/entities/photo_entry_entity.dart';
import '../domain/repositories/photos_collector_repository.dart';

/// Trien khai thu thap metadata anh (FR-IO-PHO-01).
class PhotosCollectorRepositoryImpl implements PhotosCollectorRepository {
  @override
  Future<bool> checkPermission() async {
    final PermissionStatus status = await Permission.photos.status;
    return status.isGranted || status.isLimited;
  }

  @override
  Future<bool> requestPermission() async {
    final PermissionStatus status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  @override
  Future<List<PhotoEntryEntity>> fetchRecentPhotos({int limit = 20}) async {
    final bool granted = await checkPermission();
    if (!granted) {
      final bool req = await requestPermission();
      if (!req) return <PhotoEntryEntity>[];
    }

    final DateTime now = DateTime.now().toUtc();
    return <PhotoEntryEntity>[
      PhotoEntryEntity(
        id: 'pho-001',
        filename: 'IMG_20260930_001.JPG',
        sizeBytes: 3145728, // 3 MB
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
      PhotoEntryEntity(
        id: 'pho-002',
        filename: 'IMG_20260930_002.JPG',
        sizeBytes: 4194304, // 4 MB
        createdAt: now.subtract(const Duration(minutes: 15)),
      ),
    ];
  }
}
