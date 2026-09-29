import 'entities/camera_capture_entity.dart';

/// Giao dien thu thap hinh anh tu camera.
abstract class CameraCollectorRepository {
  Future<bool> checkPermission();
  Future<bool> requestPermission();
  Future<CameraCaptureEntity?> capturePhoto();
}
