/// Thuc the nhat ky truy cap va gui ket qua (Audit Log Entry).
///
/// Tang Domain thuan khiet theo SDS v4.0 Muc 2 va TC-IO-NFR-11.
/// Khong import framework ngoai, khong phu thuoc ha tang mang/csdl.
class AuditLogEntry {
  const AuditLogEntry({
    this.id,
    required this.action,
    this.target,
    required this.result,
    required this.at,
    this.platform = 'ios',
    this.sessionId,
  });

  final int? id;
  final String action;
  final String? target;
  final String result;
  final String at;
  final String platform;
  final String? sessionId;
}
