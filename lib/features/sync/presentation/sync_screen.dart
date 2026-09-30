import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/telegram_providers.dart';
import '../data/background_sync_service.dart';

/// Man hinh /sync - so goi ket qua dang cho gui.
///
/// Chi hien thi payloadKind, recordCount, attempts, nextAttemptAt.
/// KHONG hien thi payloadPath day du - duong dan trong thu muc ung dung co the
/// chua ten tep mang thong tin.
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<int> pending = ref.watch(sendQueueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hang doi gui')),
      body: pending.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            const Center(child: Text('Khong doc duoc hang doi')),
        data: (int n) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('So goi dang cho gui', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                n.toString(),
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 16),
              Text(
                n == 0
                    ? 'Khong con goi nao cho gui'
                    : 'Se thu gui lai theo backoff luy tien',
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.sync),
                label: const Text('Kích hoạt Đồng bộ Ngầm ngay'),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đang kích hoạt tác vụ nền xả hàng đợi...')),
                  );
                  await BackgroundSyncService().triggerOneOffSync();
                  // Xa truc tiep neu app dang foreground
                  try {
                    final int count = await BackgroundSyncService().drainPendingQueue();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đã đồng bộ xong! Đã gửi thành công $count gói.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi đồng bộ: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
