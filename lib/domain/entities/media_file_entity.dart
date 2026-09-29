/// Thuc the tep da phuong tien (anh, am thanh, video) o tang Domain.
///
/// Thuan khiet, khong import package ha tang.
class MediaFileEntity {
  const MediaFileEntity({
    this.id,
    required this.filePath,
    required this.mediaType,
    required this.fileSizeBytes,
    required this.collectedAt,
    this.sent = false,
  });

  final int? id;
  final String filePath;
  final String mediaType;
  final int fileSizeBytes;
  final String collectedAt;
  final bool sent;
}
