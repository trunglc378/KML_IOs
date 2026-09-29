import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../constants/telegram_config.dart';
import '../../features/sync/data/telegram_queue.dart';
import '../data/database.dart';
import '../security/secret_redactor.dart';
import 'send_result.dart';
import 'telegram_result_sender.dart';

/// Hang doi ma dispatcher can - chi bay nhieu phuong thuc no dung.
abstract class PacketQueue {
  Future<List<QueuedPacketRef>> duePackets({
    required DateTime now,
    required int maxRetry,
  });
  Future<void> markSuccess(int id);
  Future<void> markRetry(
    int id, {
    required DateTime nextAttemptAt,
    required String lastError,
  });
  Future<void> markFailed(int id, {required String lastError});
}
/// Tham chieu toi mot goi trong hang doi.
///
/// La ALIAS cua QueuedPacket - cung mot kieu, chi khac ten goi.
/// Nho vay TelegramQueue (tra ve QueuedPacket) tho duoc interface PacketQueue
/// (khai bao QueuedPacketRef) ma khong can doi kieu.
typedef QueuedPacketRef = QueuedPacket;

/// Vong lap doc queue, goi sender, xu ly ket qua, ghi log.
///
/// Day la lop DUY NHAT duoc: retry, ghi audit_log/send_log, xoa goi khoi queue.
class TelegramDispatcher {
  TelegramDispatcher({
    required PacketQueue queue,
    required TelegramResultSender sender,
    required Database db,
    required String Function() readChatId,
    /// GAP-CONTRACT-002 FIX: deviceId duoc truyen tu ngoai, KHONG hardcode.
    /// Caller lay gia tri tu UIDevice.identifierForVendor (MethodChannel) hoac
    /// tao UUID ngau nhien lan dau roi luu vao Keychain.
    required String deviceId,
  })  : _queue = queue,
        _sender = sender,
        _db = db,
        _readChatId = readChatId,
        _deviceId = deviceId;

  final PacketQueue _queue;
  final TelegramResultSender _sender;
  final Database _db;
  final String Function() _readChatId;
  final String _deviceId;

  /// Backoff luy tien: backoffBase * 2^(attempts-1).
  /// Lan 1 -> 1x, lan 2 -> 2x, lan 3 -> 4x, lan 4 -> 8x.
  static Duration backoffFor(int attempts) {
    final int exp = attempts < 1 ? 0 : attempts - 1;
    Duration d = TelegramConfig.backoffBase;
    for (int i = 0; i < exp; i++) {
      d = d * 2;
    }
    return d > TelegramConfig.backoffCap ? TelegramConfig.backoffCap : d;
  }

  /// Chay mot luot: lay goi den han, xu ly tung goi.
  ///
  /// DUNG TOAN BO vong lap khi gap fatalAuth hoac fatalConfig - cau hinh sai
  /// thi moi goi sau cung se sai. blocked va oversize chi thuoc mot goi.
  Future<int> runOnce({DateTime? now}) async {
    final DateTime t = (now ?? DateTime.now()).toUtc();
    final List<QueuedPacketRef> packets = await _queue.duePackets(
      now: t,
      maxRetry: TelegramConfig.maxRetry,
    );
    int ok = 0;
    for (final QueuedPacketRef p in packets) {
      final SendResult r = await _dispatchOne(p, t);
      if (r.status == SendStatus.success) ok++;
      if (r.status == SendStatus.fatalAuth ||
          r.status == SendStatus.fatalConfig) {
        break;
      }
    }
    return ok;
  }

  /// Xu ly mot goi theo ma tran ket qua (SDS v4.0 Muc 8.5).
  Future<SendResult> _dispatchOne(QueuedPacketRef p, DateTime now) async {
    // Doc chat_id MOT LAN, dung cho ca gui lan ghi log.
    final String chatId = _readChatId();

    List<String> records = <String>[];
    if (p.payloadPath != null && File(p.payloadPath!).existsSync()) {
      records = File(p.payloadPath!).readAsLinesSync();
    }

    final bool isImage =
        p.payloadKind == 'photo' || p.payloadKind == 'screen';
    final SendResult r = await _sender.send(
      sessionId: p.sessionId,
      deviceId: p.deviceId ?? _deviceId, // GAP-CONTRACT-002/003: uu tien deviceId tu packet neu co, fallback _deviceId
      payloadKind: p.payloadKind,
      records: records,
      filePath: isImage ? p.payloadPath : null,
      collectedAt: now,
    );

    switch (r.status) {
      case SendStatus.success:
        await _queue.markSuccess(p.id);
        await _deleteTemp(p.payloadPath);
        await _writeLogs(p, r, SendOutcomeMapper.success, chatId);
        break;
      case SendStatus.retryable:
        await _handleRetryable(p, r, now, chatId);
        break;
      case SendStatus.fatalAuth:
      case SendStatus.fatalConfig:
        await _queue.markFailed(p.id,
            lastError: r.description ?? 'loi cau hinh');
        await _writeLogs(p, r, SendOutcomeMapper.fatal, chatId);
        break;
      case SendStatus.blocked:
        await _queue.markFailed(p.id,
            lastError: r.description ?? 'ngoai whitelist');
        await _writeLogs(p, r, SendOutcomeMapper.blocked, chatId);
        break;
      case SendStatus.oversize:
        await _queue.markFailed(p.id,
            lastError: r.description ?? 'tep qua lon');
        await _deleteTemp(p.payloadPath);
        await _writeLogs(p, r, SendOutcomeMapper.oversize, chatId);
        break;
    }
    return r;
  }

  /// Xu ly loi thu lai duoc.
  ///
  /// retry_after UU TIEN HON backoff (NFR-IO-16): khi Bot API tra 429 kem
  /// thoi gian cho, do la rang buoc chu khong phai goi y.
  Future<void> _handleRetryable(
    QueuedPacketRef p,
    SendResult r,
    DateTime now,
    String chatId,
  ) async {
    // Gioi han so lan thu: cham tran -> loi vinh vien, KHONG chan goi sau.
    if (p.attempts >= TelegramConfig.maxRetry) {
      await _queue.markFailed(p.id,
          lastError: r.description ?? 'vuot so lan thu toi da');
      await _writeLogs(p, r, SendOutcomeMapper.exhausted, chatId);
      return;
    }
    final Duration wait = r.retryAfter ?? backoffFor(p.attempts + 1);
    await _queue.markRetry(
      p.id,
      nextAttemptAt: now.add(wait),
      lastError: r.description ?? 'loi tam thoi',
    );
    await _writeLogs(p, r, SendOutcomeMapper.retryable, chatId);
  }

  /// Xoa tep tam sau khi goi thanh cong hoac bi bo (NFR-IO-15).
  Future<void> _deleteTemp(String? path) async {
    if (path == null) return;
    try {
      final File f = File(path);
      if (f.existsSync()) f.deleteSync();
    } on FileSystemException {
      // Khong xoa duoc tep tam khong duoc lam hong luong gui.
    }
  }

  /// Ghi send_log + audit_log cho mot lan gui.
  ///
  /// [chatId] la chat_id THAT, doc tu TokenStore. Cot chatIdSuffix CHI luu
  /// bon ky tu cuoi - khong bao gio luu day du (NFR-IO-13 / Muc 18.3).
  Future<void> _writeLogs(
    QueuedPacketRef p,
    SendResult r,
    String outcome,
    String chatId,
  ) async {
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    await _db.insert(DbTables.sendLog, <String, Object?>{
      'sessionId': p.sessionId,
      'method': r.method ?? 'sendMessage',
      // Bon ky tu cuoi - du doi chieu, khong lo day du.
      'chatIdSuffix': SecretRedactor.chatIdSuffix(chatId, keep: 4),
      'attempts': p.attempts + 1,
      'outcome': outcome,
      'sentAt': nowIso,
      'payloadKind': p.payloadKind,
      'recordCount': p.recordCount,
    });
    await _db.insert(DbTables.auditLog, <String, Object?>{
      'action': 'send_result',
      'target': p.payloadKind,
      'result': outcome,
      'at': nowIso,
      'platform': 'ios',
      'sessionId': p.sessionId,
    });
  }
}

/// Anh xa trang thai noi bo sang gia tri cot send_log.outcome (Muc 8.4).
class SendOutcomeMapper {
  SendOutcomeMapper._();
  static const String success = 'success';
  static const String retryable = 'failed_network';
  static const String fatal = 'failed_auth';
  static const String blocked = 'blocked_whitelist';
  static const String oversize = 'failed_oversize';
  static const String exhausted = 'failed_exhausted';
}
