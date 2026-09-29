import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/audit_log/presentation/audit_log_screen.dart';
import '../../features/consent/presentation/consent_screen.dart';
import '../../features/data_viewer/presentation/data_feature_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/sync/presentation/sync_screen.dart';

/// Cau hinh go_router day du cho toan bo ung dung KML-iOS (SDS v4.0 Muc 3.3).
final GoRouter appRouter = GoRouter(
  initialLocation: '/home',
  routes: <RouteBase>[
    GoRoute(
      path: '/home',
      builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (BuildContext context, GoRouterState state) =>
          const OnboardingScreen(),
    ),
    GoRoute(
      path: '/consent',
      builder: (BuildContext context, GoRouterState state) => ConsentScreen(
        onConsentAccepted: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (BuildContext context, GoRouterState state) =>
          const SettingsScreen(),
    ),
    GoRoute(
      path: '/audit-log',
      builder: (BuildContext context, GoRouterState state) =>
          const AuditLogScreen(),
    ),
    GoRoute(
      path: '/sync',
      builder: (BuildContext context, GoRouterState state) => const SyncScreen(),
    ),
    // Cac route chuc nang thu thap du lieu (/data/*)
    GoRoute(
      path: '/data/device',
      builder: (BuildContext context, GoRouterState state) =>
          const DataFeatureScreen(
        featureKey: 'device_info',
        title: 'Thiết bị & Mạng',
        icon: Icons.phone_iphone_rounded,
      ),
    ),
    GoRoute(
      path: '/data/location',
      builder: (BuildContext context, GoRouterState state) =>
          const DataFeatureScreen(
        featureKey: 'location',
        title: 'Định vị GPS',
        icon: Icons.location_on_rounded,
      ),
    ),
    GoRoute(
      path: '/data/contacts',
      builder: (BuildContext context, GoRouterState state) =>
          const DataFeatureScreen(
        featureKey: 'contacts',
        title: 'Danh bạ',
        icon: Icons.contacts_rounded,
      ),
    ),
    GoRoute(
      path: '/data/calendar',
      builder: (BuildContext context, GoRouterState state) =>
          const DataFeatureScreen(
        featureKey: 'calendar',
        title: 'Lịch sự kiện',
        icon: Icons.calendar_today_rounded,
      ),
    ),
    GoRoute(
      path: '/data/photos',
      builder: (BuildContext context, GoRouterState state) =>
          const DataFeatureScreen(
        featureKey: 'photo',
        title: 'Thư viện ảnh',
        icon: Icons.photo_library_rounded,
      ),
    ),
    GoRoute(
      path: '/data/camera',
      builder: (BuildContext context, GoRouterState state) =>
          const DataFeatureScreen(
        featureKey: 'photo',
        title: 'Camera',
        icon: Icons.camera_alt_rounded,
      ),
    ),
    GoRoute(
      path: '/data/microphone',
      builder: (BuildContext context, GoRouterState state) =>
          const DataFeatureScreen(
        featureKey: 'voice',
        title: 'Ghi âm',
        icon: Icons.mic_rounded,
      ),
    ),
    GoRoute(
      path: '/data/screen',
      builder: (BuildContext context, GoRouterState state) =>
          const DataFeatureScreen(
        featureKey: 'screen',
        title: 'Ghi màn hình',
        icon: Icons.screen_share_rounded,
      ),
    ),
  ],
);
