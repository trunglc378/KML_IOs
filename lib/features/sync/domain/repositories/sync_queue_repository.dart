import '../entities/sync_packet.dart';

/// Interface quan ly hang doi dong bo o tang Domain.
abstract class SyncQueueRepository {
  Future<void> enqueuePacket(SyncPacket packet);
  Future<int> getPendingCount();
}
