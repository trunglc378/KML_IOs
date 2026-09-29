import 'entities/calendar_event_entity.dart';

/// Giao dien thu thap su kien lich tren thiet bi.
abstract class CalendarCollectorRepository {
  Future<bool> checkPermission();
  Future<bool> requestPermission();
  Future<List<CalendarEventEntity>> fetchEvents();
}
