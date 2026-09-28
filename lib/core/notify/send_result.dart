/// Kết quả một lần gọi Bot API, đã chuẩn hoá.
///
/// Sáu trạng thái theo SDS v4.0 Mục 8.5. Dispatcher đọc trạng thái này để quyết
/// định giữ hay xoá gói khỏi hàng đợi.
///
/// Kiểu này là điểm giao giữa tầng client (bước 5), sender (bước 7) và dispatcher
/// (bước 8), nên được tách thành file riêng thay vì nhét vào client.
enum SendStatus {
  /// ok:true                              -> ghi log, xoá khỏi queue
  success,

  /// lỗi mạng, timeout, 5xx, 429          -> tăng attempts, giữ lại
  retryable,

  /// 401, token sai hoặc bị thu hồi       -> dừng gửi, không thử lại
  fatalAuth,

  /// 400, chat_id sai, chat chưa start    -> dừng gửi, không thử lại
  fatalConfig,

  /// chat_id ngoài whitelist              -> chặn, KHÔNG gọi API
  blocked,

  /// tệp vượt giới hạn sau khi chia       -> bỏ gói, ghi log lỗi
  oversize,
}

/// Kết quả một lần gọi Bot API, đã chuẩn hoá về một kiểu nội bộ thống nhất.
///
/// QUY TẮC BẮT BUỘC:
/// 1. description phải đã LỌC BÍ MẬT trước khi tạo SendResult. Không truyền
///    nguyên văn thân phản hồi của Bot API - phản hồi lỗi có thể chứa URL kèm token.
/// 2. retryAfter chỉ có giá trị khi status == retryable và Bot API trả 429.
/// 3. isTerminal trả false CHỈ cho retryable. Mọi trạng thái khác là kết thúc -
///    dispatcher không thử lại.
/// 4. toString() không in description thô; chỉ in trạng thái và mã lỗi.
class SendResult {
  const SendResult({
    required this.status,
    this.messageId,
    this.serverErrorCode,
    this.description,
    this.retryAfter,
    this.method,
  });

  final SendStatus status;

  /// message_id từ result.message_id khi thành công.
  final int? messageId;

  /// error_code của Bot API. Không phải bí mật.
  final int? serverErrorCode;

  /// Mô tả lỗi ĐÃ ĐƯỢC LỌC BÍ MẬT trước khi tạo SendResult.
  final String? description;

  /// Từ parameters.retry_after khi bị giới hạn tần suất (HTTP 429).
  /// Ưu tiên hơn backoff mặc định (SDS v4.0 Mục 8.5).
  final Duration? retryAfter;

  /// Phuong thuc Bot API da dung: sendMessage | sendDocument | sendPhoto.
  /// TelegramClient dien vao o MOI duong tra ve, ke ca nhanh loi -
  /// send_log ghi ca lan thu that bai nen van can biet phuong thuc da dinh dung.
  final String? method;

  /// Dispatcher dùng: false CHỈ khi còn được thử lại.
  bool get isTerminal => status != SendStatus.retryable;

  /// Dispatcher dùng: chỉ xoá gói khỏi queue khi thành công.
  bool get shouldDeleteFromQueue => status == SendStatus.success;
}
