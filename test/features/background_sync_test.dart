import 'package:flutter_test/flutter_test.dart';
import 'package:kml_ios/features/sync/data/background_sync_service.dart';

void main() {
  group('BackgroundSyncService Tests (FR-IO-SYN-02)', () {
    test('BackgroundSyncService singleton instance is consistent', () {
      final BackgroundSyncService s1 = BackgroundSyncService();
      final BackgroundSyncService s2 = BackgroundSyncService();
      expect(identical(s1, s2), isTrue);
    });

    test('Background sync task identifier matches iOS specification', () {
      expect(backgroundSyncTaskName, 'com.kml.ios.backgroundSync');
    });
  });
}
