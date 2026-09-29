/// Thuc the dai dien cho mot goi ket qua cho gui trong hang doi nghiep vu.
///
/// Tang Domain thuan khiet: khong chua logic SQLite, HTTP, hoac SDK ngoai.
class QueuedPacketEntity {
  const QueuedPacketEntity({
    required this.id,
    required this.sessionId,
    required this.payloadKind,
    required this.payloadPath,
    required this.recordCount,
    required this.attempts,
    required this.nextAttemptAt,
    this.deviceId,
  });

  final int id;
  final String sessionId;
  final String payloadKind;
  final String? payloadPath;
  final int recordCount;
  final int attempts;
  final String nextAttemptAt;
  final String? deviceId;

  bool get isDue {
    final DateTime? due = DateTime.tryParse(nextAttemptAt);
    if (due == null) return false;
    return DateTime.now().toUtc().isAfter(due);
  }
}
