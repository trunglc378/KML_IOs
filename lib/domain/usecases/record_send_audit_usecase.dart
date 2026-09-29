import '../../features/audit_log/domain/entities/audit_log_entry.dart';
import '../../features/audit_log/domain/repositories/audit_log_repository.dart';

/// UseCase ghi nhat ky kiem toan moi lan gui (FR-IO-CON-03).
///
/// Tang Domain thuan khiet, luu tru minh bach hanh vi gui ket qua.
class RecordSendAuditUseCase {
  const RecordSendAuditUseCase(this._repository);

  final AuditLogRepository _repository;

  Future<void> execute(AuditLogEntry entry) async {
    return _repository.record(entry);
  }
}
