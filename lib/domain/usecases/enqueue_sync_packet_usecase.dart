import '../../features/sync/domain/entities/sync_packet.dart';
import '../../features/sync/domain/repositories/sync_queue_repository.dart';

/// UseCase xep goi ket qua vao hang doi dong bo (FR-IO-SYN-01).
///
/// Tang Domain thuan khiet, khong phu thuoc Telegram hay HTTP.
class EnqueueSyncPacketUseCase {
  const EnqueueSyncPacketUseCase(this._repository);

  final SyncQueueRepository _repository;

  Future<void> execute(SyncPacket packet) async {
    return _repository.enqueuePacket(packet);
  }
}
