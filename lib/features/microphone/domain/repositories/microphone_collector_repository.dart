import 'entities/audio_recording_entity.dart';

/// Giao dien thu thap am thanh tu micro.
abstract class MicrophoneCollectorRepository {
  Future<bool> checkPermission();
  Future<bool> requestPermission();
  Future<AudioRecordingEntity?> recordSample({int durationSeconds = 10});
}
