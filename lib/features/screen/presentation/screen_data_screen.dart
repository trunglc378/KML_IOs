import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/screen_collector_repository_impl.dart';
import '../domain/entities/screen_capture_entity.dart';
import '../domain/repositories/screen_collector_repository.dart';

final screenCollectorProvider = Provider<ScreenCollectorRepository>((Ref ref) {
  return ScreenCollectorRepositoryImpl();
});

/// Man hinh thu thap chup man hinh (/data/screen).
class ScreenDataScreen extends ConsumerStatefulWidget {
  const ScreenDataScreen({super.key});

  @override
  ConsumerState<ScreenDataScreen> createState() => _ScreenDataScreenState();
}

class _ScreenDataScreenState extends ConsumerState<ScreenDataScreen> {
  ScreenCaptureEntity? _lastCapture;
  bool _capturing = false;

  Future<void> _capture() async {
    setState(() => _capturing = true);
    final ScreenCollectorRepository repo = ref.read(screenCollectorProvider);
    final ScreenCaptureEntity? result = await repo.captureScreen();
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
      appBar: AppBar(title: const Text('Ghi màn hình (Screen)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Chụp ảnh màn hình (FR-IO-SCR-01)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.screenshot),
                    label: Text(_capturing ? 'Đang chụp...' : 'Chụp màn hình ngay'),
                    onPressed: _capturing ? null : _capture,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_lastCapture != null) ...<Widget>[
            Card(
              child: ListTile(
                leading: const Icon(Icons.image, color: Colors.blueAccent),
                title: const Text('Đã chụp ảnh màn hình thành công'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Dung lượng: ${(_lastCapture!.sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB'),
                    Text('Đường dẫn: ${_lastCapture!.filePath}'),
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
