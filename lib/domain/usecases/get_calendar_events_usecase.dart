import '../entities/calendar_event_entity.dart';
import '../repositories/data_collection_repository.dart';

/// UseCase lay su kien lich (FR-IO-CAL-01).
///
/// Tang Domain thuan khiet, khong phu thuoc EventKit.
class GetCalendarEventsUseCase {
  const GetCalendarEventsUseCase(this._repository);

  final DataCollectionRepository _repository;

  Future<List<CalendarEventEntity>> execute() async {
    return _repository.getCalendarEvents();
  }
}
