import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/photos_collector_repository_impl.dart';
import '../domain/entities/photo_entry_entity.dart';
import '../domain/repositories/photos_collector_repository.dart';

final photosCollectorProvider = Provider<PhotosCollectorRepository>((Ref ref) {
  return PhotosCollectorRepositoryImpl();
});

final photosFutureProvider = FutureProvider<List<PhotoEntryEntity>>((Ref ref) async {
  final PhotosCollectorRepository repo = ref.watch(photosCollectorProvider);
  return repo.fetchRecentPhotos();
});

/// Man hinh thu thap va hien thi thu vien anh (/data/photos).
class PhotosDataScreen extends ConsumerWidget {
  const PhotosDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PhotoEntryEntity>> photos = ref.watch(photosFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư viện ảnh (Photos)'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại danh sách ảnh',
            onPressed: () => ref.refresh(photosFutureProvider),
          ),
        ],
      ),
      body: photos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, StackTrace st) => Center(
          child: Text('Lỗi truy cập thư viện ảnh: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (List<PhotoEntryEntity> items) {
          if (items.isEmpty) {
            return const Center(child: Text('Không có ảnh nào hoặc chưa cấp quyền.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(),
            itemBuilder: (BuildContext context, int index) {
              final PhotoEntryEntity p = items[index];
              final double mb = p.sizeBytes / (1024 * 1024);
              return ListTile(
                leading: const Icon(Icons.image, color: Colors.teal),
                title: Text(p.filename, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Dung lượng: ${mb.toStringAsFixed(2)} MB  ·  Tạo lúc: ${p.createdAt.toLocal()}'),
                    const SizedBox(height: 4),
                    Text(
                      p.toRecordLine(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.blueGrey),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
