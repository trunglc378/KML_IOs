import '../entities/queued_packet_entity.dart';

/// Hop dong repository cho viec quan ly hang doi va phan phoi goi ket qua.
///
/// Thuan khiet Domain: khong import bat ky thanh phan ha tang hay mang nao.
abstract class SendRepository {
  Future<void> enqueuePacket({
    required String sessionId,
    required String payloadKind,
    required String payloadPath,
    required int recordCount,
    String? deviceId,
  });

  Future<List<QueuedPacketEntity>> getPendingPackets({
    required DateTime now,
    required int maxRetry,
  });

  Future<void> markPacketSuccess(int id);

  Future<void> markPacketRetry(
    int id, {
    required DateTime nextAttemptAt,
    required String errorReason,
  });

  Future<void> markPacketFailed(int id, {required String errorReason});

  Future<int> countPending();
}
