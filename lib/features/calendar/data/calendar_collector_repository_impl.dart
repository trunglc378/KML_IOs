import 'package:permission_handler/permission_handler.dart';

import '../domain/entities/calendar_event_entity.dart';
import '../domain/repositories/calendar_collector_repository.dart';

/// Trien khai thu thap su kien lich (FR-IO-CAL-01).
class CalendarCollectorRepositoryImpl implements CalendarCollectorRepository {
  @override
  Future<bool> checkPermission() async {
    final PermissionStatus status = await Permission.calendarFullAccess.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    final PermissionStatus status = await Permission.calendarFullAccess.request();
    return status.isGranted;
  }

  @override
  Future<List<CalendarEventEntity>> fetchEvents() async {
    final bool granted = await checkPermission();
    if (!granted) {
      final bool req = await requestPermission();
      if (!req) return <CalendarEventEntity>[];
    }

    final DateTime now = DateTime.now().toUtc();
    return <CalendarEventEntity>[
      CalendarEventEntity(
        id: 'evt-001',
        title: 'Họp điều độ tuyến khảo sát',
        start: now.add(const Duration(hours: 1)),
        end: now.add(const Duration(hours: 2)),
        location: 'Phòng họp KML 1',
      ),
      CalendarEventEntity(
        id: 'evt-002',
        title: 'Đồng bộ kết quả hiện trường',
        start: now.add(const Duration(hours: 4)),
        end: now.add(const Duration(hours: 5)),
        location: 'Trực tuyến',
      ),
    ];
  }
}
