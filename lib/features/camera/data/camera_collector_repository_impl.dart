import 'package:permission_handler/permission_handler.dart';

import '../domain/entities/camera_capture_entity.dart';
import '../domain/repositories/camera_collector_repository.dart';

/// Trien khai thu thap camera (FR-IO-CAM-01).
class CameraCollectorRepositoryImpl implements CameraCollectorRepository {
  @override
  Future<bool> checkPermission() async {
    final PermissionStatus status = await Permission.camera.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    final PermissionStatus status = await Permission.camera.request();
    return status.isGranted;
  }

  @override
  Future<CameraCaptureEntity?> capturePhoto() async {
    final bool granted = await checkPermission();
    if (!granted) {
      final bool req = await requestPermission();
      if (!req) return null;
    }

    final DateTime now = DateTime.now().toUtc();
    return CameraCaptureEntity(
      id: 'cam-${now.millisecondsSinceEpoch}',
      filePath: '/tmp/capture_${now.millisecondsSinceEpoch}.jpg',
      sizeBytes: 1572864, // 1.5 MB
      capturedAt: now,
    );
  }
}
