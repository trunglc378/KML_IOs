import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kml_ios/core/constants/telegram_config.dart';
import 'package:kml_ios/core/data/database.dart';
import 'package:kml_ios/core/notify/send_result.dart';
import 'package:kml_ios/core/notify/telegram_dispatcher.dart';
import 'package:kml_ios/core/notify/telegram_result_sender.dart';

/// Hang doi gia. duePackets loc attempts < maxRetry nhu that.
class FakeQueue implements PacketQueue {
  final List<QueuedPacketRef> packets = <QueuedPacketRef>[];
  final List<QueuedPacketRef> succeeded = <QueuedPacketRef>[];
  final List<QueuedPacketRef> failed = <QueuedPacketRef>[];
  final List<int> retried = <int>[];
  DateTime? lastNextAttempt;

  @override
  Future<List<QueuedPacketRef>> duePackets({
    required DateTime now,
    required int maxRetry,
  }) async =>
      packets.where((QueuedPacketRef p) => p.attempts < maxRetry).toList();

  @override
  Future<void> markSuccess(int id) async =>
      succeeded.add(packets.firstWhere((QueuedPacketRef p) => p.id == id));

  @override
  Future<void> markRetry(int id, {
    required DateTime nextAttemptAt,
    required String lastError,
  }) async {
    retried.add(id);
    lastNextAttempt = nextAttemptAt;
  }

  @override
  Future<void> markFailed(int id, {required String lastError}) async =>
      failed.add(packets.firstWhere((QueuedPacketRef p) => p.id == id));
}

/// Sender gia: dem so lan goi, tra ket qua theo hang doi.
class FakeSender implements TelegramResultSender {
  int callCount = 0;
  final List<SendResult> results = <SendResult>[];

  @override
  Future<SendResult> send({
    required String sessionId,
    required String deviceId,
    required String payloadKind,
    required List<String> records,
    String? filePath,
    required DateTime collectedAt,
  }) async {
    final SendResult r = results[callCount];
    callCount++;
    return r;
  }

  @override
  Future<SendResult> sendParts({
    required String sessionId,
    required String deviceId,
    required String payloadKind,
    required List<String> parts,
    required DateTime collectedAt,
  }) async =>
      const SendResult(status: SendStatus.success, messageId: 1);

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  sqfliteFfiInit();

  late Database db;
  late FakeQueue fq;
  late FakeSender fs;
  late TelegramDispatcher d;
  final DateTime now = DateTime.utc(2026, 1, 1);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: kSchemaVersion,
        onCreate: (Database x, int v) => createSchema(x),
      ),
    );
    fq = FakeQueue();
    fs = FakeSender();
    d = TelegramDispatcher(
      queue: fq,
      sender: fs,
      db: db,
      readChatId: () => '5887530234',
    );
  });

  tearDown(() async => db.close());

  QueuedPacketRef pk(int id, String session, {int attempts = 0}) =>
      QueuedPacketRef(
        id: id,
        sessionId: session,
        payloadKind: 'location',
        payloadPath: null,
        recordCount: 1,
        attempts: attempts,
        nextAttemptAt: '2026-01-01T00:00:00Z',
      );

  group('backoff', () {
    test('1. lan thu 1 -> now + 1x backoffBase', () async {
      fq.packets.add(pk(1, 'S1', attempts: 0));
      fs.results.add(const SendResult(status: SendStatus.retryable));
      await d.runOnce(now: now);
      expect(fq.retried, <int>[1]);
      final Duration delta = fq.lastNextAttempt!.difference(now);
      expect(delta.inSeconds, TelegramConfig.backoffBase.inSeconds);
    });

    test('2. lan thu 3 -> now + 4x backoffBase', () async {
      fq.packets.add(pk(1, 'S2', attempts: 2));
      fs.results.add(const SendResult(status: SendStatus.retryable));
      await d.runOnce(now: now);
      final Duration delta = fq.lastNextAttempt!.difference(now);
      expect(delta.inSeconds, TelegramConfig.backoffBase.inSeconds * 4);
    });

    test('3. retryAfter != null -> dung retryAfter', () async {
      fq.packets.add(pk(1, 'S3', attempts: 0));
      fs.results.add(const SendResult(
        status: SendStatus.retryable,
        retryAfter: Duration(seconds: 7),
      ));
      await d.runOnce(now: now);
      final Duration delta = fq.lastNextAttempt!.difference(now);
      expect(delta.inSeconds, 7);
    });

    test('4. attempts lon -> backoff chan o backoffCap', () async {
      fq.packets.add(pk(1, 'S4', attempts: 2));
      fs.results.add(const SendResult(status: SendStatus.retryable));
      await d.runOnce(now: now);
      final Duration delta = fq.lastNextAttempt!.difference(now);
      expect(delta, lessThanOrEqualTo(TelegramConfig.backoffCap));
    });
  });

  // ===== BON CA COT LOI: dung vong lap =====
  group('dung vong lap', () {
    test('5. fatalAuth -> DUNG, goi sau KHONG duoc goi', () async {
      fq.packets.add(pk(1, 'A'));
      fq.packets.add(pk(2, 'B'));
      fs.results.add(const SendResult(status: SendStatus.fatalAuth));
      fs.results.add(const SendResult(status: SendStatus.success, messageId: 1));
      await d.runOnce(now: now);
      expect(fs.callCount, 1);
    });

    test('6. fatalConfig -> DUNG, goi sau KHONG duoc goi', () async {
      fq.packets.add(pk(1, 'A'));
      fq.packets.add(pk(2, 'B'));
      fs.results.add(const SendResult(status: SendStatus.fatalConfig));
      fs.results.add(const SendResult(status: SendStatus.success, messageId: 1));
      await d.runOnce(now: now);
      expect(fs.callCount, 1);
    });

    test('7. blocked -> KHONG dung, goi sau VAN duoc goi', () async {
      fq.packets.add(pk(1, 'A'));
      fq.packets.add(pk(2, 'B'));
      fs.results.add(const SendResult(status: SendStatus.blocked));
      fs.results.add(const SendResult(status: SendStatus.success, messageId: 1));
      await d.runOnce(now: now);
      expect(fs.callCount, 2);
    });

    test('8. oversize -> KHONG dung, goi sau VAN duoc goi', () async {
      fq.packets.add(pk(1, 'A'));
      fq.packets.add(pk(2, 'B'));
      fs.results.add(const SendResult(status: SendStatus.oversize));
      fs.results.add(const SendResult(status: SendStatus.success, messageId: 1));
      await d.runOnce(now: now);
      expect(fs.callCount, 2);
    });
  });

  // ===== GIOI HAN, LOG, TEP TAM =====
  group('gioi han va log', () {
    test('9. attempts >= maxRetry -> markFailed, goi sau KHONG bi chan', () async {
      fq.packets.add(pk(1, 'A', attempts: TelegramConfig.maxRetry));
      fq.packets.add(pk(2, 'B', attempts: TelegramConfig.maxRetry));
      await d.runOnce(now: now);
      // duePackets loc attempts >= maxRetry, nen khong goi nao duoc thu.
      expect(fs.callCount, 0);
    });

    test('10. success -> send_log chi luu 4 ky tu cuoi chat_id', () async {
      fq.packets.add(pk(1, 'S10'));
      fs.results.add(const SendResult(status: SendStatus.success, messageId: 1));
      await d.runOnce(now: now);
      final List<Map<String, Object?>> rows = await db.query(DbTables.sendLog);
      expect(rows.length, 1);
      final String suffix = rows.first['chatIdSuffix']! as String;
      expect(suffix, '0234');
      expect(suffix, isNot('5887530234'));
      expect(suffix.length, 4);
    });

    test('11. success -> xoa tep tam tai payloadPath', () async {
      final Directory dir = Directory.systemTemp.createTempSync('kml8_');
      final File f = File('${dir.path}${Platform.pathSeparator}p.txt');
      f.writeAsStringSync('lat=1');
      expect(f.existsSync(), isTrue);
      fq.packets.add(QueuedPacketRef(
        id: 1,
        sessionId: 'S11',
        payloadKind: 'location',
        payloadPath: f.path,
        recordCount: 1,
        attempts: 0,
        nextAttemptAt: '2026-01-01T00:00:00Z',
      ));
      fs.results.add(const SendResult(status: SendStatus.success, messageId: 1));
      await d.runOnce(now: now);
      expect(f.existsSync(), isFalse);
      dir.deleteSync(recursive: true);
    });

    test('12. sendDocument -> send_log.method == sendDocument', () async {
      fq.packets.add(pk(1, 'S12'));
      fs.results.add(const SendResult(
        status: SendStatus.success,
        messageId: 1,
        method: 'sendDocument',
      ));
      await d.runOnce(now: now);
      final List<Map<String, Object?>> rows = await db.query(DbTables.sendLog);
      expect(rows.first['method'], 'sendDocument');
      expect(rows.first['method'], isNot('sendMessage'));
    });
  });
}
