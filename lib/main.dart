import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'features/sync/data/background_sync_service.dart';

/// Diem khoi dau cua ung dung KML-iOS (SDS v4.0 Muc 2.1 & 5.1).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khoi tao va dang ky tac vu dong bo nen Workmanager (FR-IO-SYN-02)
  try {
    await BackgroundSyncService().schedulePeriodicSync();
  } catch (e) {
    debugPrint('Loi khoi tao BackgroundSyncService: $e');
  }

  runApp(
    const ProviderScope(
      child: KmlIosApp(),
    ),
  );
}

/// Root widget cua ung dung KML-iOS.
class KmlIosApp extends StatelessWidget {
  const KmlIosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KML-iOS',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
