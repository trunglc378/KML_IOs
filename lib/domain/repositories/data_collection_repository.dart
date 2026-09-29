import '../../features/device_info/domain/entities/device_info_entity.dart';
import '../../features/location/domain/entities/location_entity.dart';
import '../entities/calendar_event_entity.dart';
import '../entities/contact_entity.dart';
import '../entities/media_file_entity.dart';

/// Interface Repository thu thap du lieu o tang Domain.
///
/// UseCase goi Repository interface de thu thap, hoan toan doc lap voi nen tang.
abstract class DataCollectionRepository {
  Future<DeviceInfoEntity> getDeviceInfo();
  Future<LocationEntity> getLocation();
  Future<List<ContactEntity>> getContacts();
  Future<List<CalendarEventEntity>> getCalendarEvents();
  Future<List<MediaFileEntity>> getPhotos();
  Future<MediaFileEntity?> captureCamera();
  Future<MediaFileEntity?> recordMicrophone({int durationSeconds = 10});
  Future<MediaFileEntity?> recordScreen({int durationSeconds = 10});
}
