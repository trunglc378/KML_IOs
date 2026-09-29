import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/calendar_collector_repository_impl.dart';
import '../domain/entities/calendar_event_entity.dart';
import '../domain/repositories/calendar_collector_repository.dart';

final calendarCollectorProvider = Provider<CalendarCollectorRepository>((Ref ref) {
  return CalendarCollectorRepositoryImpl();
});

final calendarFutureProvider = FutureProvider<List<CalendarEventEntity>>((Ref ref) async {
  final CalendarCollectorRepository repo = ref.watch(calendarCollectorProvider);
  return repo.fetchEvents();
});

/// Man hinh thu thap va hien thi lich (/data/calendar).
class CalendarDataScreen extends ConsumerWidget {
  const CalendarDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<CalendarEventEntity>> events = ref.watch(calendarFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch (Calendar)'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại sự kiện',
            onPressed: () => ref.refresh(calendarFutureProvider),
          ),
        ],
      ),
      body: events.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, StackTrace st) => Center(
          child: Text('Lỗi truy cập lịch: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (List<CalendarEventEntity> items) {
          if (items.isEmpty) {
            return const Center(child: Text('Không có sự kiện nào hoặc chưa cấp quyền.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(),
            itemBuilder: (BuildContext context, int index) {
              final CalendarEventEntity e = items[index];
              return ListTile(
                leading: const Icon(Icons.event, color: Colors.indigo),
                title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Thời gian: ${e.start.toLocal()} - ${e.end.toLocal()}'),
                    if (e.location != null) Text('Địa điểm: ${e.location}'),
                    const SizedBox(height: 4),
                    Text(
                      e.toRecordLine(),
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
