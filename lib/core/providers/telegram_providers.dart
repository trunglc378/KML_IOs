import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/telegram_runtime_config.dart';
import '../constants/telegram_config.dart';
import '../data/database.dart';
import '../network/telegram_client.dart';
import '../notify/telegram_message_builder.dart';
import '../notify/telegram_result_sender.dart';
import '../security/token_store.dart';
import '../security/token_store_provider.dart';

/// Sau provider cua kenh gui ket qua (SDS v4.0 Muc 3.2).
///
/// QUY TAC: khong provider nao giu bi mat trong state. botStatusProvider
/// chi giu TRANG THAI, khong giu token hay chat_id.

/// 1. Cau hinh bot da nap tu Keychain (bat dong bo).
///
/// Tra ve TelegramRuntimeConfig; status la mot trong ba muc.
final telegramConfigProvider = FutureProvider<TelegramRuntimeConfig>(
  (Ref ref) async {
    final TokenStore s = ref.watch(tokenStoreProvider);
    final String? token = await s.readBotToken();
    final String? chatId = await s.readChatId();
    return TelegramRuntimeConfig(
      botToken: token,
      chatId: chatId,
      whitelist: TelegramConfig.whitelist,
    );
  },
);

/// 2. Instance client dio rieng cho Bot API.
///
/// buildDio() dung base URL va timeout chuan (Muc 7.2), validateStatus luon true.
final telegramClientProvider = Provider<TelegramClient>((Ref ref) {
  return TelegramClient(TelegramClient.buildDio(), ref.watch(tokenStoreProvider));
});

/// 3. Instance TelegramResultSender.
///
/// Day la noi DUY NHAT quyet dinh gui van ban hay gui tep (SDS Muc 6.4).
final resultSenderProvider = Provider<TelegramResultSender>((Ref ref) {
  return TelegramResultSender(
    client: ref.watch(telegramClientProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    builder: const TelegramMessageBuilder(),
  );
});

/// 4. So goi dang cho gui, cho man hinh /sync.
///
/// StreamProvider: phat lai khi queue thay doi. O day tra ve so goi cho gui
/// dua tren bang telegram_queue; man hinh lang nghe de cap nhat.
final sendQueueProvider = StreamProvider<int>((Ref ref) async* {
  final Database db = await ref.watch(databaseProvider.future);
  yield await _countPending(db);
});

Future<int> _countPending(Database db) async {
  final List<Map<String, Object?>> r = await db.rawQuery(
    'SELECT COUNT(*) AS c FROM ' + DbTables.telegramQueue +
    ' WHERE terminal = 0',
  );
  return (r.first['c'] as int?) ?? 0;
}

/// Provider mo CSDL local. Man hinh /sync va /audit-log doc tu day.
final databaseProvider = FutureProvider<Database>((Ref ref) async {
  return databaseFactory.openDatabase(
    kDatabaseName,
    options: OpenDatabaseOptions(
      version: kSchemaVersion,
      onCreate: (Database d, int v) => createSchema(d),
    ),
  );
});

/// 5. Trang thai cau hinh bot: da cau hinh / chua cau hinh / khong hop le.
///
/// BAT BUOC la AsyncNotifier, KHONG dung FutureProvider (SDS Muc 3.2):
/// trang thai phai CAP NHAT LAI duoc sau khi nguoi dung doi cau hinh.
/// FutureProvider tinh mot lan va khong cho phep dieu do.
///
/// KHONG giu token hay chat_id trong state - chi giu TRANG THAI.
class BotStatusNotifier extends AsyncNotifier<BotConfigStatus> {
  @override
  Future<BotConfigStatus> build() async {
    return _compute();
  }

  /// Tinh lai trang thai. Goi sau khi nguoi dung doi cau hinh.
  Future<void> refresh() async {
    state = const AsyncValue<BotConfigStatus>.loading();
    state = await AsyncValue.guard<BotConfigStatus>(_compute);
  }

  Future<BotConfigStatus> _compute() async {
    final TokenStore s = ref.read(tokenStoreProvider);
    final String? token = await s.readBotToken();
    final String? chatId = await s.readChatId();
    final TelegramRuntimeConfig cfg = TelegramRuntimeConfig(
      botToken: token,
      chatId: chatId,
      whitelist: TelegramConfig.whitelist,
    );
    return cfg.status;
  }
}

final botStatusProvider =
    AsyncNotifierProvider<BotStatusNotifier, BotConfigStatus>(
  BotStatusNotifier.new,
);

/// Mot dong send_log da doc ra, dung cho man hinh /audit-log.
///
/// chatIdSuffix da chi co 4 ky tu cuoi - khong can che them (NFR-IO-13).
class SendLogRow {
  const SendLogRow({
    required this.sentAt,
    required this.sessionId,
    required this.method,
    required this.chatIdSuffix,
    required this.attempts,
    required this.outcome,
  });
  final String sentAt;
  final String sessionId;
  final String method;
  final String chatIdSuffix;
  final int attempts;
  final String outcome;
}

/// 6. Danh sach ban ghi gui, cho man hinh /audit-log.
///
/// Sap xep moi nhat truoc. Day la NGUON TRA CUU DUY NHAT sau khi doi kenh,
/// vi khong con Dashboard (Muc 17 cua prompt).
final auditLogProvider = StreamProvider<List<SendLogRow>>((Ref ref) async* {
  final Database db = await ref.watch(databaseProvider.future);
  final List<Map<String, Object?>> rows = await db.query(
    DbTables.sendLog,
    orderBy: 'sentAt DESC',
  );
  yield rows.map((Map<String, Object?> r) => SendLogRow(
        sentAt: (r['sentAt'] as String?) ?? '',
        sessionId: (r['sessionId'] as String?) ?? '',
        method: (r['method'] as String?) ?? 'sendMessage',
        chatIdSuffix: (r['chatIdSuffix'] as String?) ?? '',
        attempts: (r['attempts'] as int?) ?? 1,
        outcome: (r['outcome'] as String?) ?? 'unknown',
      )).toList();
});
