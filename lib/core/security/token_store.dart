import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Doc/ghi bot token va chat_id qua Keychain cua chinh app.
/// SDS v4.0 Muc 2.3 / NFR-IO-05.
///
/// QUY TAC:
/// - Bi mat KHONG BAO GIO vao SQLite thuong (Muc 8.1).
/// - Bi mat KHONG BAO GIO vao shared_preferences.
/// - Lop nay KHONG ghi log gia tri bi mat.
/// - Chat ID chi duoc ghi 4 ky tu cuoi khi can doi chieu.
///
/// Ghi chu Data Protection (Muc 10): Keychain dung class
/// first_unlock_this_device de tranh doc bi mat khi may dang khoa.
class TokenStore {
  TokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;

  // ===== Ham che bi mat (thuan, test duoc khong can thiet bi) =====

  /// Che bot token, giu lai bot_id de chan doan.
  /// '8920168927:AAEabcXYZ' -> '8920168927:*'
  /// Chuoi khong co dau hai cham -> '*'
  static String maskToken(String token) {
    final int sep = token.indexOf(':');
    if (sep <= 0) return '*';
    return '${token.substring(0, sep)}:*';
  }

  /// Che chat_id, giu lai 4 ky tu cuoi de doi chieu.
  /// '5887530234'   -> '*0234'
  /// '-5022357153'  -> '*7153'
  /// Chuoi ngan hon 4 ky tu -> '*'
  static String maskChatId(String chatId) {
    if (chatId.length <= 4) return '*'.padRight(chatId.length, '*');
    return '*${chatId.substring(chatId.length - 4)}';
  }

  // ===== Doc/ghi Keychain =====

  /// Doc bot token. Tra ve null neu chua cau hinh.
  Future<String?> readBotToken() => _storage.read(key: _kToken);

  /// Doc chat_id dich. Tra ve null neu chua cau hinh.
  Future<String?> readChatId() => _storage.read(key: _kChatId);

  /// Ghi bot token. Khong ghi log gia tri.
  Future<void> writeBotToken(String token) =>
      _storage.write(key: _kToken, value: token);

  /// Ghi chat_id. Khong ghi log gia tri.
  Future<void> writeChatId(String chatId) =>
      _storage.write(key: _kChatId, value: chatId);

  /// Xoa toan bo bi mat cua ung dung.
  Future<void> clear() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kChatId);
  }

  /// Cho biet da co du token va chat_id chua, KHONG tra ve gia tri.
  Future<bool> hasCredentials() async {
    final String? t = await readBotToken();
    final String? c = await readChatId();
    return t != null && t.isNotEmpty && c != null && c.isNotEmpty;
  }

  static const String _kToken = 'kml_ios.telegram.bot_token';
  static const String _kChatId = 'kml_ios.telegram.chat_id';
}
