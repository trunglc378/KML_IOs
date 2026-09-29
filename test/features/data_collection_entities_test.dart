import 'package:flutter_test/flutter_test.dart';
import 'package:kml_ios/features/calendar/domain/entities/calendar_event_entity.dart';
import 'package:kml_ios/features/camera/domain/entities/camera_capture_entity.dart';
import 'package:kml_ios/features/contacts/domain/entities/contact_entry_entity.dart';
import 'package:kml_ios/features/device/domain/entities/device_metadata_entity.dart';
import 'package:kml_ios/features/location/domain/entities/location_entity.dart';
import 'package:kml_ios/features/microphone/domain/entities/audio_recording_entity.dart';
import 'package:kml_ios/features/photos/domain/entities/photo_entry_entity.dart';
import 'package:kml_ios/features/screen/domain/entities/screen_capture_entity.dart';

void main() {
  group('Data Collection Entities format tests (SDS v4.0 Muc 6.5)', () {
    test('1. DeviceMetadataEntity toRecordLines formats DTO properly', () {
      final DeviceMetadataEntity dev = DeviceMetadataEntity(
        deviceId: 'device-test-01',
        name: 'iPhone 15 Pro',
        model: 'iPhone',
        systemName: 'iOS',
        systemVersion: '17.4',
        localizedModel: 'iPhone',
        batteryLevel: 0.85,
        isBatteryMonitoringEnabled: true,
        isPhysicalDevice: true,
        collectedAt: DateTime.utc(2026, 9, 25, 8, 0, 0),
      );

      final List<String> lines = dev.toRecordLines();
      expect(lines.length, 4);
      expect(lines[0], contains('model=iPhone'));
      expect(lines[1], contains('system=iOS 17.4'));
      expect(lines[2], 'battery=85.0%');
      expect(lines[3], contains('collected=2026-09-25T08:00:00.000Z'));
    });

    test('2. LocationEntity toRecordLine formats DTO matching SDS 6.5', () {
      final LocationEntity loc = LocationEntity(
        latitude: 21.028512,
        longitude: 105.854215,
        accuracy: 10.0,
        altitude: 12.5,
        speed: 0.0,
        heading: 180.0,
        timestamp: DateTime.utc(2026, 9, 25, 8, 0, 0),
      );

      final String line = loc.toRecordLine();
      expect(line, 'lat=21.028512 lon=105.854215 acc=10.0 alt=12.5 speed=0.0 bearing=180.0 at=2026-09-25T08:00:00.000Z');
    });

    test('3. ContactEntryEntity toRecordLine formats DTO properly', () {
      const ContactEntryEntity c = ContactEntryEntity(
        id: 'c-1',
        displayName: 'John Doe',
        phones: <String>['0912345678'],
        emails: <String>['john@example.com'],
      );
      expect(c.toRecordLine(), 'id=c-1 name="John Doe" phones=["0912345678"] emails=["john@example.com"]');
    });

    test('4. CalendarEventEntity toRecordLine formats DTO properly', () {
      final CalendarEventEntity cal = CalendarEventEntity(
        id: 'cal-1',
        title: 'Survey Meeting',
        start: DateTime.utc(2026, 9, 25, 8, 0, 0),
        end: DateTime.utc(2026, 9, 25, 9, 0, 0),
        location: 'HQ Room 101',
      );
      expect(cal.toRecordLine(), 'id=cal-1 title="Survey Meeting" start=2026-09-25T08:00:00.000Z end=2026-09-25T09:00:00.000Z loc="HQ Room 101"');
    });

    test('5. PhotoEntryEntity toRecordLine formats DTO properly', () {
      final PhotoEntryEntity pho = PhotoEntryEntity(
        id: 'pho-1',
        filename: 'field.jpg',
        sizeBytes: 1024000,
        createdAt: DateTime.utc(2026, 9, 25, 8, 0, 0),
      );
      expect(pho.toRecordLine(), 'id=pho-1 name="field.jpg" size=1024000 at=2026-09-25T08:00:00.000Z');
    });

    test('6. CameraCaptureEntity toRecordLine formats DTO properly', () {
      final CameraCaptureEntity cam = CameraCaptureEntity(
        id: 'cam-1',
        filePath: '/tmp/c.jpg',
        sizeBytes: 500000,
        capturedAt: DateTime.utc(2026, 9, 25, 8, 0, 0),
      );
      expect(cam.toRecordLine(), 'id=cam-1 size=500000 at=2026-09-25T08:00:00.000Z path="/tmp/c.jpg"');
    });

    test('7. AudioRecordingEntity toRecordLine formats DTO properly', () {
      final AudioRecordingEntity mic = AudioRecordingEntity(
        id: 'mic-1',
        filePath: '/tmp/m.m4a',
        durationSeconds: 15,
        sizeBytes: 120000,
        recordedAt: DateTime.utc(2026, 9, 25, 8, 0, 0),
      );
      expect(mic.toRecordLine(), 'id=mic-1 dur=15s size=120000 at=2026-09-25T08:00:00.000Z path="/tmp/m.m4a"');
    });

    test('8. ScreenCaptureEntity toRecordLine formats DTO properly', () {
      final ScreenCaptureEntity scr = ScreenCaptureEntity(
        id: 'scr-1',
        filePath: '/tmp/s.png',
        sizeBytes: 900000,
        isImage: true,
        capturedAt: DateTime.utc(2026, 9, 25, 8, 0, 0),
      );
      expect(scr.toRecordLine(), 'id=scr-1 kind=image size=900000 at=2026-09-25T08:00:00.000Z path="/tmp/s.png"');
    });
  });
}
