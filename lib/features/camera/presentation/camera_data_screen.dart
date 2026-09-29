import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/camera_collector_repository_impl.dart';
import '../domain/entities/camera_capture_entity.dart';
import '../domain/repositories/camera_collector_repository.dart';

final cameraCollectorProvider = Provider<CameraCollectorRepository>((Ref ref) {
  return CameraCollectorRepositoryImpl();
});

/// Man hinh thu thap may anh (/data/camera).
class CameraDataScreen extends ConsumerStatefulWidget {
  const CameraDataScreen({super.key});

  @override
  ConsumerState<CameraDataScreen> createState() => _CameraDataScreenState();
}

class _CameraDataScreenState extends ConsumerState<CameraDataScreen> {
  CameraCaptureEntity? _lastCapture;
  bool _capturing = false;

  Future<void> _takePhoto() async {
    setState(() => _capturing = true);
    final CameraCollectorRepository repo = ref.read(cameraCollectorProvider);
    final CameraCaptureEntity? result = await repo.capturePhoto();
    if (mounted) {
      setState(() {
        _lastCapture = result;
        _capturing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Máy ảnh (Camera)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Chụp ảnh hiện trường (FR-IO-CAM-01)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text(_capturing ? 'Đang chụp...' : 'Chụp ảnh tức thì'),
                    onPressed: _capturing ? null : _takePhoto,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_lastCapture != null) ...<Widget>[
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Đã chụp thành công'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Đường dẫn: ${_lastCapture!.filePath}'),
                    Text('Kích thước: ${(_lastCapture!.sizeBytes / 1024).toStringAsFixed(1)} KB'),
                    const SizedBox(height: 4),
                    Text(
                      _lastCapture!.toRecordLine(),
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
