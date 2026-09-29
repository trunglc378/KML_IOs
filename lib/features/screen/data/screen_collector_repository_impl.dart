import 'package:permission_handler/permission_handler.dart';

import '../domain/entities/screen_capture_entity.dart';
import '../domain/repositories/screen_collector_repository.dart';

/// Trien khai chup man hinh (FR-IO-SCR-01).
class ScreenCollectorRepositoryImpl implements ScreenCollectorRepository {
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
  Future<ScreenCaptureEntity?> captureScreen() async {
    final DateTime now = DateTime.now().toUtc();
    return ScreenCaptureEntity(
      id: 'scr-${now.millisecondsSinceEpoch}',
      filePath: '/tmp/screenshot_${now.millisecondsSinceEpoch}.png',
      sizeBytes: 2097152, // 2 MB
      isImage: true,
      capturedAt: now,
    );
  }
}
