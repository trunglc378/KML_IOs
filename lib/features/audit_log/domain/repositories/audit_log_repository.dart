import '../entities/audit_log_entry.dart';

/// Interface Repository nhat ky kiem toan o tang Domain.
///
/// UseCase goi Repository interface - KHONG biet gi ve Telegram hay HTTP (Muc 3.2).
abstract class AuditLogRepository {
  Future<void> record(AuditLogEntry entry);
  Future<List<AuditLogEntry>> getRecentEntries({int limit = 50});
}
