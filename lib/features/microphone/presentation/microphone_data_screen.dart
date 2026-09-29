import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/microphone_collector_repository_impl.dart';
import '../domain/entities/audio_recording_entity.dart';
import '../domain/repositories/microphone_collector_repository.dart';

final microphoneCollectorProvider = Provider<MicrophoneCollectorRepository>((Ref ref) {
  return MicrophoneCollectorRepositoryImpl();
});

/// Man hinh thu thap am thanh micro (/data/microphone).
class MicrophoneDataScreen extends ConsumerStatefulWidget {
  const MicrophoneDataScreen({super.key});

  @override
  ConsumerState<MicrophoneDataScreen> createState() => _MicrophoneDataScreenState();
}

class _MicrophoneDataScreenState extends ConsumerState<MicrophoneDataScreen> {
  AudioRecordingEntity? _lastRecording;
  bool _recording = false;

  Future<void> _startRecording() async {
    setState(() => _recording = true);
    final MicrophoneCollectorRepository repo = ref.read(microphoneCollectorProvider);
    final AudioRecordingEntity? result = await repo.recordSample(durationSeconds: 5);
    if (mounted) {
      setState(() {
        _lastRecording = result;
        _recording = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ghi âm (Microphone)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Thu âm mẫu hiện trường (FR-IO-MIC-01)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.mic),
                    label: Text(_recording ? 'Đang thu mẫu 5s...' : 'Ghi âm mẫu 5s'),
                    onPressed: _recording ? null : _startRecording,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_lastRecording != null) ...<Widget>[
            Card(
              child: ListTile(
                leading: const Icon(Icons.audiotrack, color: Colors.deepOrange),
                title: const Text('Đã thu âm mẫu thành công'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Độ dài: ${_lastRecording!.durationSeconds}s  ·  Dung lượng: ${(_lastRecording!.sizeBytes / 1024).toStringAsFixed(1)} KB'),
                    Text('Đường dẫn: ${_lastRecording!.filePath}'),
                    const SizedBox(height: 4),
                    Text(
                      _lastRecording!.toRecordLine(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
