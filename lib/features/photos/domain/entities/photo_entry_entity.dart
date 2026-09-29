/// Thuc the anh trong thu vien (FR-IO-PHO-01).
///
/// Tang Domain thuan khiet, khong phu thuoc platform hay SDK ngoai.
class PhotoEntryEntity {
  const PhotoEntryEntity({
    required this.id,
    required this.filename,
    required this.sizeBytes,
    required this.createdAt,
    this.localPath,
  });

  final String id;
  final String filename;
  final int sizeBytes;
  final DateTime createdAt;
  final String? localPath;

  /// Dinh dang DTO mot dong (SDS Muc 6.5):
  /// id=pho-1 name="IMG_0001.JPG" size=2048576 at=...
  String toRecordLine() {
    return 'id=$id name="$filename" size=$sizeBytes at=${createdAt.toUtc().toIso8601String()}';
  }
}
