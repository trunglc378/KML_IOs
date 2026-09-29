import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kml_ios/app/router/app_router.dart';
import 'package:kml_ios/app/theme/app_theme.dart';
import 'package:kml_ios/core/constants/telegram_runtime_config.dart';
import 'package:kml_ios/core/providers/telegram_providers.dart';

class _FakeBotStatusNotifier extends BotStatusNotifier {
  _FakeBotStatusNotifier(this._status);
  final BotConfigStatus _status;

  @override
  Future<BotConfigStatus> build() async => _status;
}

Widget _buildTestApp() {
  return ProviderScope(
    overrides: <Override>[
      botStatusProvider.overrideWith(
        () => _FakeBotStatusNotifier(BotConfigStatus.configured),
      ),
      sendQueueProvider.overrideWith((ref) => Stream.value(0)),
    ],
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    ),
  );
}

void main() {
  setUp(() {
    appRouter.go('/home');
  });

  testWidgets('1. App khoi chay o man hinh Home va hien thi tieu de KML-iOS v4.0',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('KML-iOS v4.0'), findsOneWidget);
    expect(find.text('Hệ thống & Kiểm toán'), findsOneWidget);
    expect(find.text('Mô-đun thu thập dữ liệu'), findsOneWidget);
    expect(find.text('Bot đã cấu hình · Kênh sẵn sàng'), findsOneWidget);
  });

  testWidgets('2. Tu Home chuyen huong den man hinh /settings',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    final Finder settingsBtn = find.byIcon(Icons.settings_outlined);
    expect(settingsBtn, findsOneWidget);
    await tester.tap(settingsBtn);
    await tester.pumpAndSettle();

    expect(find.text('Cai dat kenh gui'), findsOneWidget);
  });

  testWidgets('3. Tu Home chuyen huong den man hinh /sync',
      (WidgetTester tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    final Finder syncTile = find.text('Hàng đợi gửi (Telegram Queue)');
    expect(syncTile, findsOneWidget);
    await tester.tap(syncTile);
    await tester.pumpAndSettle();

    expect(find.text('Hang doi gui'), findsOneWidget);
  });
}
