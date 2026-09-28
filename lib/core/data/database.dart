import 'package:sqflite/sqflite.dart';

/// Ten bang - tap trung mot cho.
class DbTables {
  DbTables._();
  static const String auditLog = 'audit_log';
  static const String telegramQueue = 'telegram_queue';
  static const String sendLog = 'send_log';
}

const int kSchemaVersion = 1;
const String kDatabaseName = 'kml_ios.db';

/// Cau lenh tao bang, chay trong onCreate.
///
/// LUU Y: moi phan tu la MOT cau SQL hoan chinh, NHIEU DONG.
/// Dung raw string ba dau nhay bao quanh CA CAU, khong bao quanh tung dong -
/// neu bao quanh tung dong, SQLite se nhan cau lenh bi cat cut.

const List<String> kCreateStatements = <String>[
  // audit_log - nhat ky truy cap, phuc vu kiem toan (Muc 8.2).
'''
CREATE TABLE audit_log (
  id        INTEGER PRIMARY KEY AUTOINCREMENT,
  action    TEXT    NOT NULL,
  target    TEXT,
  result    TEXT    NOT NULL,
  at        TEXT    NOT NULL,
  platform  TEXT    NOT NULL DEFAULT 'ios',
  sessionId TEXT
)
''',
  // telegram_queue - moi dong la MOT GOI ket qua cho gui (Muc 8.3).
'''
CREATE TABLE telegram_queue (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  sessionId     TEXT    NOT NULL,
  payloadKind   TEXT    NOT NULL,
  payloadPath   TEXT,
  recordCount   INTEGER NOT NULL DEFAULT 0,
  attempts      INTEGER NOT NULL DEFAULT 0,
  lastError     TEXT,
  createdAt     TEXT    NOT NULL,
  nextAttemptAt TEXT    NOT NULL,
  deviceId      TEXT,
  terminal      INTEGER NOT NULL DEFAULT 0
)
''',
  // send_log - nguon tra cuu duy nhat sau khi doi kenh (Muc 8.4).
'''
CREATE TABLE send_log (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  sessionId     TEXT    NOT NULL,
  method        TEXT    NOT NULL,
  chatIdSuffix  TEXT,
  attempts      INTEGER NOT NULL DEFAULT 1,
  outcome       TEXT    NOT NULL,
  sentAt        TEXT    NOT NULL,
  payloadKind   TEXT,
  recordCount   INTEGER,
  deviceId      TEXT,
  detail        TEXT
)
''',
];

/// Chi muc bat buoc (Muc 8.3 / 8.4).
///
/// QUAN TRONG: unique index tren (sessionId, payloadKind) de CHONG DAY TRUNG
/// mot goi vao queue. Index tren nextAttemptAt de lay nhanh goi den han.
const List<String> kCreateIndexStatements = <String>[
'CREATE INDEX idx_tq_next_attempt ON telegram_queue (nextAttemptAt)',
'CREATE UNIQUE INDEX idx_tq_session_kind ON telegram_queue (sessionId, payloadKind)',
'CREATE INDEX idx_tq_terminal ON telegram_queue (terminal)',
'CREATE INDEX idx_sl_session ON send_log (sessionId)',
'CREATE INDEX idx_sl_sent_at ON send_log (sentAt)',
'CREATE INDEX idx_al_at ON audit_log (at)',
];

/// Tao schema tren mot CSDL da mo.
Future<void> createSchema(Database db) async {
  final Batch b = db.batch();
  for (final String sql in kCreateStatements) {
    b.execute(sql);
  }
  for (final String sql in kCreateIndexStatements) {
    b.execute(sql);
  }
  await b.commit(noResult: true);
}
