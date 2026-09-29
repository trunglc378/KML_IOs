/// Thuc the anh / video chup ghi man hinh (FR-IO-SCR-01).
///
/// Tang Domain thuan khiet, khong phu thuoc platform hay SDK ngoai.
class ScreenCaptureEntity {
  const ScreenCaptureEntity({
    required this.id,
    required this.filePath,
    required this.sizeBytes,
    required this.isImage,
    required this.capturedAt,
  });

  final String id;
  final String filePath;
  final int sizeBytes;
  final bool isImage;
  final DateTime capturedAt;

  /// Dinh dang DTO mot dong (SDS Muc 6.5):
  /// id=scr-1 kind=image size=1048576 at=... path="..."
  String toRecordLine() {
    final String kind = isImage ? 'image' : 'video';
    return 'id=$id kind=$kind size=$sizeBytes at=${capturedAt.toUtc().toIso8601String()} path="$filePath"';
  }
}
