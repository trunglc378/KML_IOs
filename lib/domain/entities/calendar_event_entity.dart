/// Thuc the su kien lich o tang Domain (SDS v4.0 Muc 8.2).
///
/// Thuan khiet, khong import package ha tang.
class CalendarEventEntity {
  const CalendarEventEntity({
    this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.collectedAt,
    this.sent = false,
  });

  final int? id;
  final String title;
  final String startAt;
  final String endAt;
  final String collectedAt;
  final bool sent;
}
