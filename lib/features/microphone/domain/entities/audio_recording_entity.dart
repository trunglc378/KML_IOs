/// Thuc the mau ghi am hien truong (FR-IO-MIC-01).
///
/// Tang Domain thuan khiet, khong phu thuoc platform hay SDK ngoai.
class AudioRecordingEntity {
  const AudioRecordingEntity({
    required this.id,
    required this.filePath,
    required this.durationSeconds,
    required this.sizeBytes,
    required this.recordedAt,
  });

  final String id;
  final String filePath;
  final int durationSeconds;
  final int sizeBytes;
  final DateTime recordedAt;

  /// Dinh dang DTO mot dong (SDS Muc 6.5):
  /// id=mic-1 dur=15s size=245760 at=... path="..."
  String toRecordLine() {
    return 'id=$id dur=${durationSeconds}s size=$sizeBytes at=${recordedAt.toUtc().toIso8601String()} path="$filePath"';
  }
}
