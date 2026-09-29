import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/telegram_providers.dart';

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
            ],
          ),
        ),
      ),
    );
  }
}
