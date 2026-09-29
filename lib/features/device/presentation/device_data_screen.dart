import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/device_collector_repository_impl.dart';
import '../domain/entities/device_metadata_entity.dart';
import '../domain/repositories/device_collector_repository.dart';

final deviceCollectorProvider = Provider<DeviceCollectorRepository>((Ref ref) {
  return DeviceCollectorRepositoryImpl();
});

final deviceInfoFutureProvider = FutureProvider<DeviceMetadataEntity>((Ref ref) async {
  final DeviceCollectorRepository repo = ref.watch(deviceCollectorProvider);
  return repo.collectDeviceInfo();
});

/// Man hinh thu thap va hien thi thong tin thiet bi (/data/device).
class DeviceDataScreen extends ConsumerWidget {
  const DeviceDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<DeviceMetadataEntity> devInfo = ref.watch(deviceInfoFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thong tin thiet bi'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(deviceInfoFutureProvider),
          ),
        ],
      ),
      body: devInfo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, StackTrace st) => Center(
          child: Text('Loi thu thap: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (DeviceMetadataEntity info) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: ListTile(
                leading: const Icon(Icons.perm_device_information, color: Colors.blue),
                title: Text('Mã thiết bị (deviceId)'),
                subtitle: SelectableText(info.deviceId, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone_iphone),
                title: Text('Tên & Mẫu'),
                subtitle: Text('${info.name} (${info.model})'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.memory),
                title: Text('Hệ điều hành'),
                subtitle: Text('${info.systemName} ${info.systemVersion}'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.battery_charging_full, color: Colors.green),
                title: Text('Trạng thái pin'),
                subtitle: Text('${(info.batteryLevel * 100).toStringAsFixed(1)}%'),
              ),
            ),
            const SizedBox(height: 24),
            Text('Định dạng DTO dòng chuẩn (SDS Mục 6.5):', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                info.toRecordLines().join('\n'),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
