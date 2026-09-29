/// Thuc the ket qua chup anh camera (FR-IO-CAM-01).
///
/// Tang Domain thuan khiet, khong phu thuoc platform hay SDK ngoai.
class CameraCaptureEntity {
  const CameraCaptureEntity({
    required this.id,
    required this.filePath,
    required this.sizeBytes,
    required this.capturedAt,
  });

  final String id;
  final String filePath;
  final int sizeBytes;
  final DateTime capturedAt;

  /// Dinh dang DTO mot dong (SDS Muc 6.5):
  /// id=cam-1 path="..." size=1048576 at=...
  String toRecordLine() {
    return 'id=$id size=$sizeBytes at=${capturedAt.toUtc().toIso8601String()} path="$filePath"';
  }
}
