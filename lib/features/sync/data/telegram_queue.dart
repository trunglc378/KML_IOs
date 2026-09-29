import 'package:sqflite/sqflite.dart';

import '../../../core/data/database.dart';
import '../../../core/notify/telegram_dispatcher.dart';
import '../../../core/security/secret_redactor.dart';

/// Mot goi ket qua cho gui, doc tu bang telegram_queue.
class QueuedPacket {
  const QueuedPacket({
    required this.id,
    required this.sessionId,
    required this.payloadKind,
    required this.payloadPath,
    required this.recordCount,
    required this.attempts,
    required this.nextAttemptAt,
  });

  final int id;
  final String sessionId;
  final String payloadKind;
  final String? payloadPath;
  final int recordCount;
  final int attempts;
  final String nextAttemptAt;
}

/// Truy cap bang telegram_queue.
///
/// Lop nay chi doc/ghi hang doi. Viec quyet dinh thu lai thuoc dispatcher.
class TelegramQueue implements PacketQueue {
  // implements PacketQueue de dispatcher dung truc tiep duoc.
  // Dispatcher chi biet interface, khong biet chi tiet SQLite.
  TelegramQueue(this.db);

  final Database db;

  /// Day mot goi vao queue. Dung INSERT OR IGNORE de unique index
  /// (sessionId, payloadKind) chan day trung.
  Future<void> enqueue({
    required String sessionId,
    required String payloadKind,
    required String payloadPath,
    required int recordCount,
  }) async {
    final String now = DateTime.now().toUtc().toIso8601String();
    await db.insert(
      DbTables.telegramQueue,
      <String, Object?>{
        'sessionId': sessionId,
        'payloadKind': payloadKind,
        'payloadPath': payloadPath,
        'recordCount': recordCount,
        'attempts': 0,
        'createdAt': now,
        'nextAttemptAt': now,
        'terminal': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// Goi den han thu: attempts < maxRetry VA nextAttemptAt <= now
  /// VA chua bi danh dau loi vinh vien (terminal = 0).
  @override
  Future<List<QueuedPacket>> duePackets({
    required DateTime now,
    required int maxRetry,
  }) async {
    final String nowIso = now.toUtc().toIso8601String();
    final List<Map<String, Object?>> rows = await db.query(
      DbTables.telegramQueue,
      where: 'attempts < ? AND nextAttemptAt <= ? AND terminal = 0',
      whereArgs: <Object?>[maxRetry, nowIso],
      orderBy: 'nextAttemptAt ASC',
    );
    return rows.map((Map<String, Object?> r) => QueuedPacket(
          id: r['id'] as int,
          sessionId: r['sessionId'] as String,
          payloadKind: r['payloadKind'] as String,
          payloadPath: r['payloadPath'] as String?,
          recordCount: (r['recordCount'] as int?) ?? 0,
          attempts: (r['attempts'] as int?) ?? 0,
          nextAttemptAt: r['nextAttemptAt'] as String,
        )).toList();
  }

  /// Goi gui thanh cong: xoa khoi queue.
  @override
  Future<void> markSuccess(int id) async {
    await db.delete(DbTables.telegramQueue,
        where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Goi thu lai: tang attempts, dat nextAttemptAt, luu lastError DA LOC.
  @override
  Future<void> markRetry(
    int id, {
    required DateTime nextAttemptAt,
    required String lastError,
  }) async {
    final List<Map<String, Object?>> cur = await db.query(
      DbTables.telegramQueue,
      columns: <String>['attempts'],
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
    final int curAttempts =
        cur.isEmpty ? 0 : (cur.first['attempts'] as int? ?? 0);
    await db.update(
      DbTables.telegramQueue,
      <String, Object?>{
        'attempts': curAttempts + 1,
        'nextAttemptAt':
            nextAttemptAt.toUtc().toIso8601String(),
        // lastError phai da loc bi mat truoc khi ghi (NFR-IO-13).
        'lastError': SecretRedactor.redactText(lastError),
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Loi vinh vien: danh dau terminal = 1 de goi ra khoi vong thu,
  /// KHONG chan cac goi phia sau (FR-IO-NOT-04 tieu chi 4).
  @override
  Future<void> markFailed(int id, {required String lastError}) async {
    await db.update(
      DbTables.telegramQueue,
      <String, Object?>{
        'terminal': 1,
        'lastError': SecretRedactor.redactText(lastError),
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// So goi dang cho gui (chua terminal).
  Future<int> countPending() async {
    final List<Map<String, Object?>> r = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DbTables.telegramQueue} WHERE terminal = 0',
    );
    return (r.first['c'] as int?) ?? 0;
  }
}
