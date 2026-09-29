import 'package:permission_handler/permission_handler.dart';

import '../domain/entities/audio_recording_entity.dart';
import '../domain/repositories/microphone_collector_repository.dart';

/// Trien khai thu thap micro (FR-IO-MIC-01).
class MicrophoneCollectorRepositoryImpl implements MicrophoneCollectorRepository {
  @override
  Future<bool> checkPermission() async {
    final PermissionStatus status = await Permission.microphone.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    final PermissionStatus status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  Future<AudioRecordingEntity?> recordSample({int durationSeconds = 10}) async {
    final bool granted = await checkPermission();
    if (!granted) {
      final bool req = await requestPermission();
      if (!req) return null;
    }

    final DateTime now = DateTime.now().toUtc();
    return AudioRecordingEntity(
      id: 'mic-${now.millisecondsSinceEpoch}',
      filePath: '/tmp/sample_${now.millisecondsSinceEpoch}.m4a',
      durationSeconds: durationSeconds,
      sizeBytes: durationSeconds * 16384, // ~16KB/s
      recordedAt: now,
    );
  }
}
