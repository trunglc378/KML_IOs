import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/location_collector_repository_impl.dart';
import '../domain/entities/location_entity.dart';
import '../domain/repositories/location_collector_repository.dart';

final locationCollectorProvider = Provider<LocationCollectorRepository>((Ref ref) {
  return LocationCollectorRepositoryImpl();
});

final singleLocationFutureProvider = FutureProvider.autoDispose<LocationEntity?>((Ref ref) async {
  final LocationCollectorRepository repo = ref.watch(locationCollectorProvider);
  return repo.getCurrentLocation();
});

/// Man hinh thu thap va giam sat toa do GPS (/data/location).
class LocationDataScreen extends ConsumerStatefulWidget {
  const LocationDataScreen({super.key});

  @override
  ConsumerState<LocationDataScreen> createState() => _LocationDataScreenState();
}

class _LocationDataScreenState extends ConsumerState<LocationDataScreen> {
  bool _isContinuous = false;
  final List<LocationEntity> _history = <LocationEntity>[];

  @override
  Widget build(BuildContext context) {
    final AsyncValue<LocationEntity?> loc = ref.watch(singleLocationFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toạ độ định vị (GPS)'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Lấy vị trí tức thì',
            onPressed: () => ref.refresh(singleLocationFutureProvider),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Vị trí hiện tại',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  loc.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (Object err, StackTrace st) => Text(
                      'Lỗi truy cập vị trí: $err',
                      style: const TextStyle(color: Colors.red),
                    ),
                    data: (LocationEntity? data) {
                      if (data == null) {
                        return const Text('Chưa có dữ liệu vị trí hoặc quyền bị từ chối.');
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Vĩ độ (Lat): ${data.latitude}'),
                          Text('Kinh độ (Lon): ${data.longitude}'),
                          Text('Độ chính xác: ±${data.accuracy.toStringAsFixed(1)} m'),
                          Text('Thời gian: ${data.timestamp.toLocal()}'),
                          const Divider(height: 20),
                          const Text('Định dạng DTO dòng chuẩn (SDS Mục 6.5):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 4),
                          SelectableText(
                            data.toRecordLine(),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                _isContinuous ? Icons.location_searching : Icons.location_disabled,
                color: _isContinuous ? Colors.green : Colors.grey,
              ),
              title: const Text('Theo dõi toạ độ liên tục'),
              subtitle: const Text('Thu thập luồng dữ liệu theo thời gian thực (FR-IO-LOC-02)'),
              value: _isContinuous,
              onChanged: (bool value) {
                setState(() {
                  _isContinuous = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
