import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/telegram_config.dart';
import '../../../core/notify/telegram_dispatcher.dart';
import '../../../core/providers/telegram_providers.dart';
import '../../sync/data/telegram_queue.dart';

/// Man hinh chi tiet cho tung chuc nang thu thap du lieu (/data/*).
///
/// Ho tro thu thap mau va day vao telegram_queue theo dung quy tac 6.2 va SDS v4.0.
class DataFeatureScreen extends ConsumerStatefulWidget {
  const DataFeatureScreen({
    super.key,
    required this.featureKey,
    required this.title,
    required this.icon,
  });

  final String featureKey;
  final String title;
  final IconData icon;

  @override
  ConsumerState<DataFeatureScreen> createState() => _DataFeatureScreenState();
}

class _DataFeatureScreenState extends ConsumerState<DataFeatureScreen> {
  bool _isCollecting = false;
  String _statusMessage = 'Sẵn sàng thu thập dữ liệu.';

  Future<void> _collectAndEnqueue() async {
    setState(() {
      _isCollecting = true;
      _statusMessage = 'Đang thu thập và chuẩn hoá DTO...';
    });

    try {
      final db = await ref.read(databaseProvider.future);
      final queue = TelegramQueue(db);
      final sessionId = 'SES-${DateTime.now().millisecondsSinceEpoch}';

      // Tao noi dung ban ghi mau theo loai
      final String nowUtc = DateTime.now().toUtc().toIso8601String();
      final List<String> sampleRecords = <String>[
        'platform=ios · deviceId=ios-dev-001 · item=1 at=$nowUtc',
        'platform=ios · deviceId=ios-dev-001 · item=2 at=$nowUtc',
      ];

      // Ghi vao telegram_queue
      await queue.enqueue(
        sessionId: sessionId,
        payloadKind: widget.featureKey,
        payloadPath: '', // Khong co file vat ly cho ban ghi van ban ngan
        recordCount: sampleRecords.length,
      );

      // Kich hoat Dispatcher bat dong bo khong chan UI (NFR-IO-14)
      final sender = ref.read(resultSenderProvider);
      final dispatcher = TelegramDispatcher(
        queue: queue,
        sender: sender,
        db: db,
        readChatId: () {
          // Doc chatId dong bo tu runtime config
          return TelegramConfig.whitelist.isNotEmpty
              ? TelegramConfig.whitelist.first
              : '';
        },
      );

      // Chay dispatcher trong background
      // ignore: unawaited_futures
      dispatcher.runOnce();

      if (mounted) {
        setState(() {
          _isCollecting = false;
          _statusMessage =
              'Đã đẩy gói $sessionId (${sampleRecords.length} bản ghi) vào hàng đợi Telegram!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xếp hàng gói kết quả $sessionId'),
            action: SnackBarAction(
              label: 'Xem Queue',
              onPressed: () => context.push('/sync'),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCollecting = false;
          _statusMessage = 'Lỗi thu thập: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    Icon(widget.icon, size: 56, color: const Color(0xFF007AFF)),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Mã loại (payloadKind): ${widget.featureKey}',
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _isCollecting ? null : _collectAndEnqueue,
              icon: _isCollecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isCollecting
                    ? 'Đang xử lý...'
                    : 'Thu thập & Đẩy vào hàng đợi gửi',
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
