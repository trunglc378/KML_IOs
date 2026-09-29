import 'entities/screen_capture_entity.dart';

/// Giao dien chup hoac ghi man hinh thiet bi.
abstract class ScreenCollectorRepository {
  Future<bool> checkPermission();
  Future<bool> requestPermission();
  Future<ScreenCaptureEntity?> captureScreen();
}
