import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:kml_ios/core/data/database.dart';
import 'package:kml_ios/features/sync/data/telegram_queue.dart';

void main() {
  sqfliteFfiInit();

  late Database db;
  late TelegramQueue q;

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: kSchemaVersion,
        onCreate: (Database d, int v) => createSchema(d),
      ),
    );
    q = TelegramQueue(db);
  });

  tearDown(() async => db.close());

  test('1. enqueue roi duePackets tra ve dung goi', () async {
    await q.enqueue(sessionId: 'S1', payloadKind: 'location',
        payloadPath: '/tmp/a', recordCount: 3);
    final List<QueuedPacket> r = await q.duePackets(
        now: DateTime.now().toUtc(), maxRetry: 5);
    expect(r.length, 1);
    expect(r.first.sessionId, 'S1');
    expect(r.first.payloadKind, 'location');
  });

  test('2. nextAttemptAt trong tuong lai -> KHONG tra ve', () async {
    await q.enqueue(sessionId: 'S2', payloadKind: 'location',
        payloadPath: '/tmp/b', recordCount: 1);
    await q.markRetry(1, nextAttemptAt: DateTime.now().toUtc().add(const Duration(hours: 1)), lastError: 'x');
    final List<QueuedPacket> r = await q.duePackets(
        now: DateTime.now().toUtc(), maxRetry: 5);
    expect(r, isEmpty);
  });

  test('3. attempts >= maxRetry -> KHONG tra ve', () async {
    await q.enqueue(sessionId: 'S3', payloadKind: 'location',
        payloadPath: '/tmp/c', recordCount: 1);
    final List<QueuedPacket> r = await q.duePackets(
        now: DateTime.now().toUtc(), maxRetry: 0);
    expect(r, isEmpty);
  });

  test('4. enqueue trung (sessionId, payloadKind) -> KHONG tao hai dong', () async {
    await q.enqueue(sessionId: 'S4', payloadKind: 'location',
        payloadPath: '/tmp/d', recordCount: 1);
    await q.enqueue(sessionId: 'S4', payloadKind: 'location',
        payloadPath: '/tmp/d2', recordCount: 9);
    expect(await q.countPending(), 1);
  });

  test('5. markSuccess -> goi ra khoi duePackets', () async {
    await q.enqueue(sessionId: 'S5', payloadKind: 'location',
        payloadPath: '/tmp/e', recordCount: 1);
    await q.markSuccess(1);
    final List<QueuedPacket> r = await q.duePackets(
        now: DateTime.now().toUtc(), maxRetry: 5);
    expect(r, isEmpty);
    expect(await q.countPending(), 0);
  });

  test('6. markRetry -> attempts tang, nextAttemptAt duoc dat', () async {
    await q.enqueue(sessionId: 'S6', payloadKind: 'location',
        payloadPath: '/tmp/f', recordCount: 1);
    await q.markRetry(1, nextAttemptAt: DateTime.now().toUtc(), lastError: 'loi');
    final List<QueuedPacket> r = await q.duePackets(
        now: DateTime.now().toUtc(), maxRetry: 5);
    expect(r.length, 1);
    expect(r.first.attempts, 1);
  });

  test('7. markFailed -> ra khoi duePackets, goi SAU khong bi chan', () async {
    await q.enqueue(sessionId: 'S7a', payloadKind: 'location',
        payloadPath: '/tmp/g', recordCount: 1);
    await q.enqueue(sessionId: 'S7b', payloadKind: 'contacts',
        payloadPath: '/tmp/h', recordCount: 1);
    await q.markFailed(1, lastError: 'loi vinh vien');
    final List<QueuedPacket> r = await q.duePackets(
        now: DateTime.now().toUtc(), maxRetry: 5);
    expect(r.length, 1);
    expect(r.first.sessionId, 'S7b');
  });

  test('8. countPending dem dung', () async {
    await q.enqueue(sessionId: 'S8a', payloadKind: 'location',
        payloadPath: '/tmp/i', recordCount: 1);
    await q.enqueue(sessionId: 'S8b', payloadKind: 'contacts',
        payloadPath: '/tmp/j', recordCount: 1);
    expect(await q.countPending(), 2);
    await q.markSuccess(1);
    expect(await q.countPending(), 1);
  });
}
