/// Kiểu lỗi nội bộ của ứng dụng — không phụ thuộc `dio` để tầng Domain
/// có thể dùng mà không vi phạm TC-IO-NFR-11.
library;

/// Lỗi cơ sở của ứng dụng.
class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;

  /// Nguyên nhân gốc (đã được lọc bí mật trước khi truyền vào).
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// Lỗi cấu hình — token sai, chat_id sai, chat chưa start bot.
class ConfigException extends AppException {
  const ConfigException(super.message, {super.cause});
}

/// Lỗi xác thực — HTTP 401, token bị thu hồi.
class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

/// Lỗi mạng — socket error, timeout. Thuộc nhóm thử lại được.
class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

/// Lỗi phía máy chủ Telegram — HTTP 5xx. Thuộc nhóm thử lại được.
class ServerException extends AppException {
  const ServerException(super.message, {super.cause});
}

/// Bị giới hạn tần suất — HTTP 429 kèm `retry_after` (Mục 7.3 quy tắc 3).
class RateLimitException extends AppException {
  const RateLimitException(super.message, {required this.retryAfter, super.cause});

  /// Thời gian chờ bắt buộc do máy chủ trả về. LUÔN ưu tiên hơn backoff mặc định.
  final Duration retryAfter;
}

/// chat_id nằm ngoài whitelist. Chặn ngay tại chỗ, KHÔNG phát sinh request
/// ra ngoài (Mục 7.4 / FR-IO-NOT-03).
class BlockedDestinationException extends AppException {
  const BlockedDestinationException(super.message, {super.cause});
}

/// Tệp vượt 50 MB ngay cả sau khi chia (Mục 7.4 trạng thái `oversize`).
class OversizeException extends AppException {
  const OversizeException(super.message, {super.cause});
}

/// Dữ liệu hỏng / không đóng gói được — lỗi vĩnh viễn, không thử lại.
class InvalidPayloadException extends AppException {
  const InvalidPayloadException(super.message, {super.cause});
}
