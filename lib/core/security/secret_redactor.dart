/// Che bí mật trước khi ghi log — NFR-IO-13 / ràng buộc Mục 1.5.
///
/// QUY TẮC: bot token và chat_id KHÔNG BAO GIỜ xuất hiện trong log, kể cả log
/// debug, kể cả trong thông báo lỗi, kể cả trong URL.
///
/// Lớp này là chốt chặn duy nhất cho mọi chỗ ghi log liên quan tới Telegram.
/// Mọi `print` / `debugPrint` / `log` phải đi qua đây.
library;

class SecretRedactor {
  SecretRedactor._();

  /// Chuỗi thay thế cố định. Không chứa thông tin về độ dài bí mật.
  static const String mask = '***';

  /// Bot token có dạng `<bot_id>:<secret>` (ví dụ `123456789:AA...`).
  /// Che phần secret, chỉ giữ lại phần `bot_id` vì bot_id KHÔNG phải bí mật
  /// và cần thiết để chẩn đoán. Kết quả: `123456789:***`.
  static String redactToken(String? token) {
    if (token == null || token.isEmpty) return '<chưa cấu hình>';
    final int sep = token.indexOf(':');
    if (sep <= 0) return mask;
    final String botId = token.substring(0, sep);
    return '$botId:$mask';
  }

  /// Che chat_id, chỉ giữ [keep] ký tự cuối (mặc định 4) — Mục 8.4 / Mục 9.3.
  /// chat_id dạng số âm với nhóm, dạng số dương với chat cá nhân.
  static String redactChatId(String? chatId, {int keep = 4}) {
    if (chatId == null || chatId.isEmpty) return '<chưa cấu hình>';
    final String trimmed = chatId.trim();
    if (trimmed.length <= keep) return mask;
    return '$mask${trimmed.substring(trimmed.length - keep)}';
  }

  /// Lấy [keep] ký tự cuối của chat_id để ghi vào `send_log.chatIdSuffix`.
  /// Trả về chuỗi rỗng nếu chat_id không hợp lệ.
  static String chatIdSuffix(String? chatId, {int keep = 4}) {
    if (chatId == null || chatId.isEmpty) return '';
    final String trimmed = chatId.trim();
    if (trimmed.length <= keep) return trimmed;
    return trimmed.substring(trimmed.length - keep);
  }

  /// Che mọi token và chat_id đã biết xuất hiện trong một chuỗi bất kỳ.
  ///
  /// Dùng cho thông báo lỗi và URL trước khi ghi log. Đây là biện pháp phòng
  /// thủ theo chiều sâu: kể cả khi lập trình viên vô tình nội suy URL đầy đủ
  /// vào thông báo lỗi, bí mật vẫn bị che.
  static String redactText(
    String? input, {
    String? token,
    String? chatId,
  }) {
    if (input == null || input.isEmpty) return '';
    String out = input;

    // Che token: cả dạng đầy đủ lẫn chỉ phần secret sau dấu ':'.
    if (token != null && token.isNotEmpty) {
      out = out.replaceAll(token, redactToken(token));
      final int sep = token.indexOf(':');
      if (sep > 0 && sep < token.length - 1) {
        final String secret = token.substring(sep + 1);
        if (secret.length >= 8) {
          out = out.replaceAll(secret, mask);
        }
      }
    }

    // Che chat_id đầy đủ.
    if (chatId != null && chatId.isNotEmpty) {
      out = out.replaceAll(chatId, redactChatId(chatId));
    }

    // Phòng thủ bổ sung: che mẫu URL Bot API `/bot<token>/` nếu còn sót.
    // Mẫu: /bot  theo sau là các ký tự không phải '/' và có chứa ':'
    out = out.replaceAllMapped(
      RegExp(r'/bot([0-9]{4,}):[A-Za-z0-9_\-]+'),
      (Match m) => '/bot${m.group(1)}:$mask',
    );

    return out;
  }
}
