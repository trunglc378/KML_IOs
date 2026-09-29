import 'package:sqflite/sqflite.dart';

import '../../../../core/data/database.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/repositories/audit_log_repository.dart';

/// Hien thuc SendAuditRepository o tang Data (SDS v4.0 Muc 2.3 & 3.4).
///
/// Ghi ban ghi nhat ky moi lan gui vao audit_log va send_log de phuc vu kiem toan.
class SendAuditRepository implements AuditLogRepository {
  SendAuditRepository(this._db);

  final Database _db;

  @override
  Future<void> record(AuditLogEntry entry) async {
    await _db.insert(
      DbTables.auditLog,
      <String, Object?>{
        'action': entry.action,
        if (entry.target != null) 'target': entry.target,
        'result': entry.result,
        'at': entry.at,
        'platform': entry.platform,
        if (entry.sessionId != null) 'sessionId': entry.sessionId,
      },
    );
  }

  @override
  Future<List<AuditLogEntry>> getRecentEntries({int limit = 50}) async {
    final List<Map<String, Object?>> rows = await _db.query(
      DbTables.auditLog,
      orderBy: 'at DESC',
      limit: limit,
    );
    return rows.map((Map<String, Object?> r) => AuditLogEntry(
          id: r['id'] as int?,
          action: r['action'] as String,
          target: r['target'] as String?,
          result: r['result'] as String,
          at: r['at'] as String,
          platform: (r['platform'] as String?) ?? 'ios',
          sessionId: r['sessionId'] as String?,
        )).toList();
  }
}
