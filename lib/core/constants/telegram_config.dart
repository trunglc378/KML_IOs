/// Cau hinh kenh gui Telegram.
///
/// Nguyen tac (SDS v4.0 Muc 3.5, 6.6, 11.2.1):
/// - Hang so dung chung          -> khai bao tai day
/// - Gia tri phu thuoc flavor    -> nap qua dart-define
/// - Bi mat (BOT_TOKEN, CHAT_ID) -> KHONG o day; lay tu TokenStore
class TelegramConfig {
  TelegramConfig._();

  // ===== Hang so, khong doi theo moi truong =====
  static const String apiBase = 'https://api.telegram.org';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 60);

  // ===== Gioi han Bot API =====
  static const int maxMessageLength = 4096;
  static const int maxUploadBytes = 50 * 1024 * 1024;
  static const int maxPhotoBytes = 10 * 1024 * 1024;

  // ===== Gia tri theo flavor (dart-define) =====
  static const String flavor =
      String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const Duration timeout =
      Duration(seconds: int.fromEnvironment('TIMEOUT_SECONDS', defaultValue: 15));
  static const int maxRetry =
      int.fromEnvironment('MAX_RETRY', defaultValue: 3);
  static const Duration backoffBase =
      Duration(seconds: int.fromEnvironment('BACKOFF_BASE_SECONDS', defaultValue: 1));

  /// Tran cua backoff luy tien. Khong de backoff tang vo han khi maxRetry lon.
  /// Hang so chung, khong theo flavor - luoi an toan, khong phai tham so van hanh.
  static const Duration backoffCap = Duration(minutes: 2);
  static const int packThreshold =
      int.fromEnvironment('PACK_THRESHOLD', defaultValue: 10);
  static const Duration packMaxAge =
      Duration(seconds: int.fromEnvironment('PACK_MAX_AGE_SECONDS', defaultValue: 60));

  /// Whitelist chat_id cua flavor dang chay (SDS v4.0 Muc 11.2.1).
  /// dev     -> chi 5887530234
  /// staging -> chi -5152160106
  /// prod    -> chi -5022357153
  /// Tra ve rong neu flavor khong nhan dien duoc -> moi lan gui bi chan.
  static List<String> get whitelist => switch (flavor) {
        'prod' => const ['-5022357153'],
        'staging' => const ['-5152160106'],
        'dev' => const ['5887530234'],
        _ => const <String>[],
      };

  /// Kiem tra chat_id co thuoc whitelist cua flavor dang chay.
  /// Goi ham nay TRUOC khi phat sinh bat ky request nao ra ngoai.
  /// false -> trang thai blocked: chan ngay, ghi canh bao, KHONG goi Bot API.
  static bool isAllowedChat(String chatId) => whitelist.contains(chatId);
}
