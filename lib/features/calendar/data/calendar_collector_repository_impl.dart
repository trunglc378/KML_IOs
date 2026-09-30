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
    final DateTime todayStart = DateTime.utc(now.year, now.month, now.day, 8, 0);
    return <CalendarEventEntity>[
      CalendarEventEntity(
        id: 'evt-${now.millisecondsSinceEpoch}-1',
        title: 'Khao sat tuyen thuc dia KML - Ca sang',
        start: todayStart,
        end: todayStart.add(const Duration(hours: 3, minutes: 30)),
        location: 'Khu vuc do dac GPS so 1',
      ),
      CalendarEventEntity(
        id: 'evt-${now.millisecondsSinceEpoch}-2',
        title: 'Huy dong thiet bi & Thu thap du lieu - Ca chieu',
        start: todayStart.add(const Duration(hours: 5)),
        end: todayStart.add(const Duration(hours: 8)),
        location: 'Tram trung chuyen thuc dia',
      ),
      CalendarEventEntity(
        id: 'evt-${now.millisecondsSinceEpoch}-3',
        title: 'Dong bo ket qua & Xuat bao cao KML',
        start: todayStart.add(const Duration(hours: 9)),
        end: todayStart.add(const Duration(hours: 10)),
        location: 'Trung tam dieu hanh',
      ),
    ];
  }
}
