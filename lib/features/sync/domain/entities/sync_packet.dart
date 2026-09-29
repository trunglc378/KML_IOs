/// Thuc the goi ket qua dong bo o tang Domain.
///
/// Thuan khiet, khong phu thuoc package ngoai.
class SyncPacket {
  const SyncPacket({
    this.id,
    required this.sessionId,
    required this.payloadKind,
    this.payloadPath,
    this.recordCount = 0,
    this.attempts = 0,
    this.lastError,
    required this.createdAt,
    required this.nextAttemptAt,
    this.deviceId,
    this.isTerminal = false,
  });

  final int? id;
  final String sessionId;
  final String payloadKind;
  final String? payloadPath;
  final int recordCount;
  final int attempts;
  final String? lastError;
  final String createdAt;
  final String nextAttemptAt;
  final String? deviceId;
  final bool isTerminal;
}
