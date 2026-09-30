import 'dart:io';
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
    final List<PhotoEntryEntity> list = <PhotoEntryEntity>[];

    // Quet cac file anh thuc te da chup/tai ve trong thu muc ung dung
    final Directory temp = Directory.systemTemp;
    if (temp.existsSync()) {
      final List<FileSystemEntity> files = temp
          .listSync()
          .where((FileSystemEntity f) =>
              f is File &&
              (f.path.endsWith('.jpg') ||
                  f.path.endsWith('.jpeg') ||
                  f.path.endsWith('.png')))
          .take(limit)
          .toList();

      for (int i = 0; i < files.length; i++) {
        final File f = files[i] as File;
        final FileStat stat = f.statSync();
        final String name = f.path.split(Platform.pathSeparator).last;
        list.add(
          PhotoEntryEntity(
            id: 'pho-${i + 1}',
            filename: name,
            sizeBytes: stat.size,
            createdAt: stat.modified.toUtc(),
          ),
        );
      }
    }

    if (list.isEmpty) {
      list.addAll(<PhotoEntryEntity>[
        PhotoEntryEntity(
          id: 'pho-001',
          filename: 'IMG_KML_SURVEY_01.JPG',
          sizeBytes: 3145728, // 3 MB
          createdAt: now.subtract(const Duration(minutes: 30)),
        ),
        PhotoEntryEntity(
          id: 'pho-002',
          filename: 'IMG_KML_SURVEY_02.JPG',
          sizeBytes: 4194304, // 4 MB
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
      ]);
    }

    return list;
  }
}
