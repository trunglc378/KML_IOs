import '../security/secret_redactor.dart';

/// Trạng thái cấu hình bot ở ba mức — Mục 12.2 / FR-IO-NOT-03 / TC-IO-UI-06.
enum BotConfigStatus {
  /// Đã có token và chat_id hợp lệ về mặt hình thức.
  configured,

  /// Chưa nạp token hoặc chat_id.
  notConfigured,

  /// Có nạp nhưng không hợp lệ (token sai định dạng, chat_id ngoài whitelist,
  /// hoặc `getMe` thất bại).
  invalid,
}

/// Cấu hình bot đã nạp từ Keychain, kèm whitelist.
///
/// Đây là đối tượng bất biến truyền giữa các lớp. `toString()` được ghi đè để
/// KHÔNG BAO GIỜ lộ bí mật — kể cả khi đối tượng bị vô tình nội suy vào log.
class TelegramRuntimeConfig {
  const TelegramRuntimeConfig({
    required this.botToken,
    required this.chatId,
    required this.whitelist,
  });

  /// Cấu hình rỗng — dùng khi chưa nạp được gì từ Keychain.
  static const TelegramRuntimeConfig empty = TelegramRuntimeConfig(
    botToken: null,
    chatId: null,
    whitelist: <String>[],
  );

  final String? botToken;
  final String? chatId;
  final List<String> whitelist;

  bool get hasToken => botToken != null && botToken!.isNotEmpty;
  bool get hasChatId => chatId != null && chatId!.isNotEmpty;

  /// Trạng thái cấu hình. Việc kiểm tra "không hợp lệ" ở đây chỉ dựa trên
  /// hình thức; tính hợp lệ thực sự của token do `getMe` xác nhận (Mục 12.2).
  BotConfigStatus get status {
    if (!hasToken && !hasChatId) return BotConfigStatus.notConfigured;
    if (!hasToken || !hasChatId) return BotConfigStatus.notConfigured;
    if (!isTokenWellFormed(botToken!)) return BotConfigStatus.invalid;
    if (whitelist.isNotEmpty && !whitelist.contains(chatId)) {
      // chat_id đích không nằm trong whitelist → cấu hình không hợp lệ.
      return BotConfigStatus.invalid;
    }
    return BotConfigStatus.configured;
  }

  /// Bot token hợp lệ về hình thức khi có dạng `<số>:<chuỗi>`.
  /// KHÔNG xác nhận token còn hiệu lực — việc đó cần gọi `getMe`.
  static bool isTokenWellFormed(String token) {
    final int sep = token.indexOf(':');
    if (sep <= 0 || sep == token.length - 1) return false;
    final String botId = token.substring(0, sep);
    if (!RegExp(r'^[0-9]{4,}$').hasMatch(botId)) return false;
    return token.substring(sep + 1).length >= 20;
  }

  /// Đối chiếu chat_id với whitelist TRƯỚC MỖI LẦN GỬI (FR-IO-NOT-03 /
  /// NFR-IO-17). Whitelist rỗng ⇒ coi như chưa cấu hình ⇒ từ chối gửi
  /// ("thà chậm còn hơn gửi sai đích" — quy tắc 6.2 số 8).
  bool isDestinationAllowed(String destination) {
    if (whitelist.isEmpty) return false;
    return whitelist.contains(destination);
  }

  TelegramRuntimeConfig copyWith({
    String? botToken,
    String? chatId,
    List<String>? whitelist,
  }) =>
      TelegramRuntimeConfig(
        botToken: botToken ?? this.botToken,
        chatId: chatId ?? this.chatId,
        whitelist: whitelist ?? this.whitelist,
      );

  /// GHI ĐÈ BẮT BUỘC: không bao giờ để bí mật lọt vào log qua `toString()`.
  @override
  String toString() =>
      'TelegramRuntimeConfig(status=${status.name}, '
      'token=${SecretRedactor.redactToken(botToken)}, '
      'chatId=${SecretRedactor.redactChatId(chatId)}, '
      'whitelistCount=${whitelist.length})';
}
