import 'package:flutter_test/flutter_test.dart';
import 'package:kml_ios/features/audit_log/data/repositories/send_audit_repository.dart';
import 'package:kml_ios/features/audit_log/domain/entities/audit_log_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SendAuditRepository Tests', () {
    late Database db;
    late SendAuditRepository repository;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (d, v) async {
          await d.execute('''
            CREATE TABLE audit_log (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              action TEXT NOT NULL,
              target TEXT,
              result TEXT NOT NULL,
              at TEXT NOT NULL,
              platform TEXT NOT NULL DEFAULT 'ios',
              sessionId TEXT
            )
          ''');
        },
      );
      repository = SendAuditRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('record saves entry and getRecentEntries retrieves it', () async {
      const entry = AuditLogEntry(
        action: 'send_telegram',
        target: 'device_info',
        result: 'SUCCESS',
        at: '2026-09-29T16:00:00Z',
        sessionId: 'SESS-100',
      );

      await repository.record(entry);

      final logs = await repository.getRecentEntries(limit: 10);
      expect(logs.length, equals(1));
      expect(logs.first.sessionId, equals('SESS-100'));
      expect(logs.first.action, equals('send_telegram'));
      expect(logs.first.result, equals('SUCCESS'));
    });
  });
}
