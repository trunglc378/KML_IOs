/// Thuc the su kien lich (FR-IO-CAL-01).
///
/// Tang Domain thuan khiet, khong phu thuoc platform hay SDK ngoai.
class CalendarEventEntity {
  const CalendarEventEntity({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.location,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String? location;

  /// Dinh dang DTO mot dong (SDS Muc 6.5):
  /// id=cal-1 title="Hop khao sat" start=... end=... loc="Ha Noi"
  String toRecordLine() {
    final String locStr = location != null ? ' loc="$location"' : '';
    return 'id=$id title="$title" start=${start.toUtc().toIso8601String()} end=${end.toUtc().toIso8601String()}$locStr';
  }
}
