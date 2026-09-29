import 'package:flutter_test/flutter_test.dart';
import 'package:kml_ios/domain/entities/calendar_event_entity.dart';
import 'package:kml_ios/domain/entities/contact_entity.dart';
import 'package:kml_ios/domain/entities/media_file_entity.dart';
import 'package:kml_ios/domain/repositories/data_collection_repository.dart';
import 'package:kml_ios/domain/usecases/capture_camera_usecase.dart';
import 'package:kml_ios/domain/usecases/enqueue_sync_packet_usecase.dart';
import 'package:kml_ios/domain/usecases/get_calendar_events_usecase.dart';
import 'package:kml_ios/domain/usecases/get_contacts_usecase.dart';
import 'package:kml_ios/domain/usecases/get_device_info_usecase.dart';
import 'package:kml_ios/domain/usecases/get_location_usecase.dart';
import 'package:kml_ios/domain/usecases/get_photos_usecase.dart';
import 'package:kml_ios/domain/usecases/record_microphone_usecase.dart';
import 'package:kml_ios/domain/usecases/record_screen_usecase.dart';
import 'package:kml_ios/domain/usecases/record_send_audit_usecase.dart';
import 'package:kml_ios/features/audit_log/domain/entities/audit_log_entry.dart';
import 'package:kml_ios/features/audit_log/domain/repositories/audit_log_repository.dart';
import 'package:kml_ios/features/device_info/domain/entities/device_info_entity.dart';
import 'package:kml_ios/features/location/domain/entities/location_entity.dart';
import 'package:kml_ios/features/sync/domain/entities/sync_packet.dart';
import 'package:kml_ios/features/sync/domain/repositories/sync_queue_repository.dart';

class MockDataCollectionRepository implements DataCollectionRepository {
  @override
  Future<DeviceInfoEntity> getDeviceInfo() async {
    return const DeviceInfoEntity(
      deviceId: 'TEST-DEV-001',
      osVersion: 'iOS 17.4',
      model: 'iPhone 15 Pro',
      networkType: 'WiFi',
      collectedAt: '2026-09-29T16:00:00Z',
    );
  }

  @override
  Future<LocationEntity> getLocation() async {
    return const LocationEntity(
      deviceId: 'TEST-DEV-001',
      latitude: 21.0285,
      longitude: 105.8542,
      accuracy: 5.0,
      altitude: 10.0,
      speed: 0.0,
      bearing: 0.0,
      collectedAt: '2026-09-29T16:00:00Z',
    );
  }

  @override
  Future<List<ContactEntity>> getContacts() async {
    return [
      const ContactEntity(
        id: 1,
        name: 'John Doe',
        phone: '+84901234567',
        email: 'johndoe@example.com',
        collectedAt: '2026-09-29T16:00:00Z',
      ),
    ];
  }

  @override
  Future<List<CalendarEventEntity>> getCalendarEvents() async {
    return [
      const CalendarEventEntity(
        id: 1,
        title: 'Project Kickoff',
        startAt: '2026-09-29T09:00:00Z',
        endAt: '2026-09-29T10:00:00Z',
        collectedAt: '2026-09-29T16:00:00Z',
      ),
    ];
  }

  @override
  Future<List<MediaFileEntity>> getPhotos() async {
    return [
      const MediaFileEntity(
        id: 1,
        filePath: '/tmp/IMG_001.JPG',
        mediaType: 'image/jpeg',
        fileSizeBytes: 2048576,
        collectedAt: '2026-09-29T16:00:00Z',
      ),
    ];
  }

  @override
  Future<MediaFileEntity?> captureCamera() async {
    return const MediaFileEntity(
      id: 1,
      filePath: '/tmp/capture_001.jpg',
      mediaType: 'image/jpeg',
      fileSizeBytes: 1024000,
      collectedAt: '2026-09-29T16:00:00Z',
    );
  }

  @override
  Future<MediaFileEntity?> recordMicrophone({int durationSeconds = 10}) async {
    return const MediaFileEntity(
      id: 1,
      filePath: '/tmp/record_001.m4a',
      mediaType: 'audio/m4a',
      fileSizeBytes: 512000,
      collectedAt: '2026-09-29T16:00:00Z',
    );
  }

  @override
  Future<MediaFileEntity?> recordScreen({int durationSeconds = 10}) async {
    return const MediaFileEntity(
      id: 1,
      filePath: '/tmp/screen_001.mp4',
      mediaType: 'video/mp4',
      fileSizeBytes: 8192000,
      collectedAt: '2026-09-29T16:00:00Z',
    );
  }
}

class MockSyncQueueRepository implements SyncQueueRepository {
  final List<SyncPacket> queue = [];

  @override
  Future<void> enqueuePacket(SyncPacket packet) async {
    queue.add(packet);
  }

  @override
  Future<int> getPendingCount() async => queue.length;
}

class MockAuditLogRepository implements AuditLogRepository {
  final List<AuditLogEntry> logs = [];

  @override
  Future<void> record(AuditLogEntry entry) async {
    logs.add(entry);
  }

  @override
  Future<List<AuditLogEntry>> getRecentEntries({int limit = 50}) async {
    return logs.take(limit).toList();
  }
}

void main() {
  late MockDataCollectionRepository mockDataRepo;
  late MockSyncQueueRepository mockSyncRepo;
  late MockAuditLogRepository mockAuditRepo;

  setUp(() {
    mockDataRepo = MockDataCollectionRepository();
    mockSyncRepo = MockSyncQueueRepository();
    mockAuditRepo = MockAuditLogRepository();
  });

  group('Domain UseCases Execution Tests', () {
    test('GetDeviceInfoUseCase returns device entity', () async {
      final usecase = GetDeviceInfoUseCase(mockDataRepo);
      final result = await usecase.execute();
      expect(result.deviceId, equals('TEST-DEV-001'));
      expect(result.model, equals('iPhone 15 Pro'));
      expect(result.osVersion, equals('iOS 17.4'));
    });

    test('GetLocationUseCase returns valid coordinates', () async {
      final usecase = GetLocationUseCase(mockDataRepo);
      final result = await usecase.execute();
      expect(result.latitude, closeTo(21.0285, 0.001));
      expect(result.longitude, closeTo(105.8542, 0.001));
      expect(result.accuracy, equals(5.0));
    });

    test('GetContactsUseCase returns contacts list', () async {
      final usecase = GetContactsUseCase(mockDataRepo);
      final result = await usecase.execute();
      expect(result.length, equals(1));
      expect(result.first.name, equals('John Doe'));
      expect(result.first.phone, equals('+84901234567'));
    });

    test('GetCalendarEventsUseCase returns events list', () async {
      final usecase = GetCalendarEventsUseCase(mockDataRepo);
      final result = await usecase.execute();
      expect(result.length, equals(1));
      expect(result.first.title, equals('Project Kickoff'));
    });

    test('GetPhotosUseCase returns recent photos', () async {
      final usecase = GetPhotosUseCase(mockDataRepo);
      final result = await usecase.execute();
      expect(result.length, equals(1));
      expect(result.first.filePath, equals('/tmp/IMG_001.JPG'));
    });

    test('CaptureCameraUseCase returns captured photo entity', () async {
      final usecase = CaptureCameraUseCase(mockDataRepo);
      final result = await usecase.execute();
      expect(result, isNotNull);
      expect(result!.filePath, equals('/tmp/capture_001.jpg'));
    });

    test('RecordMicrophoneUseCase returns recorded audio entity', () async {
      final usecase = RecordMicrophoneUseCase(mockDataRepo);
      final result = await usecase.execute(durationSeconds: 10);
      expect(result, isNotNull);
      expect(result!.filePath, equals('/tmp/record_001.m4a'));
    });

    test('RecordScreenUseCase returns screen video entity', () async {
      final usecase = RecordScreenUseCase(mockDataRepo);
      final result = await usecase.execute(durationSeconds: 15);
      expect(result, isNotNull);
      expect(result!.filePath, equals('/tmp/screen_001.mp4'));
    });

    test('EnqueueSyncPacketUseCase adds packet to queue', () async {
      final usecase = EnqueueSyncPacketUseCase(mockSyncRepo);
      const packet = SyncPacket(
        id: 1,
        sessionId: 'SES-001',
        payloadKind: 'device_info',
        createdAt: '2026-09-29T16:00:00Z',
        nextAttemptAt: '2026-09-29T16:00:00Z',
      );
      await usecase.execute(packet);
      expect(await mockSyncRepo.getPendingCount(), equals(1));
    });

    test('RecordSendAuditUseCase logs send attempt', () async {
      final usecase = RecordSendAuditUseCase(mockAuditRepo);
      const entry = AuditLogEntry(
        id: 1,
        action: 'send_telegram',
        result: 'SUCCESS',
        at: '2026-09-29T16:00:00Z',
        sessionId: 'SES-001',
      );
      await usecase.execute(entry);
      final logs = await mockAuditRepo.getRecentEntries();
      expect(logs.length, equals(1));
      expect(logs.first.result, equals('SUCCESS'));
    });
  });
}
