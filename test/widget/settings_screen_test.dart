import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kml_ios/core/constants/telegram_runtime_config.dart';
import 'package:kml_ios/core/providers/telegram_providers.dart';
import 'package:kml_ios/core/network/telegram_client.dart';
import 'package:kml_ios/features/settings/presentation/settings_screen.dart';

/// Client gia: dem so lan getMe duoc goi, khong goi mang.
class FakeClient implements TelegramClient {
  int getMeCount = 0;
  bool result = true;

  @override
  Future<bool> getMe() async {
    getMeCount++;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// Notifier gia: tra ve trang thai cai san, khong doc Keychain.
class FakeBotStatus extends BotStatusNotifier {
  FakeBotStatus(this._initial);
  final BotConfigStatus _initial;
  @override
  Future<BotConfigStatus> build() async => _initial;
}

Widget _wrap(BotConfigStatus st, FakeClient? client) {
  return ProviderScope(
    overrides: <Override>[
      botStatusProvider.overrideWith(() => FakeBotStatus(st)),
      if (client != null)
        telegramClientProvider.overrideWithValue(client),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

void main() {
  testWidgets('1. notConfigured -> nhan chua cau hinh', (WidgetTester t) async {
    await t.pumpWidget(_wrap(BotConfigStatus.notConfigured, null));
    await t.pumpAndSettle();
    expect(find.textContaining('chua cau hinh'), findsWidgets);
  });

  testWidgets('2. invalid -> nhan khong hop le', (WidgetTester t) async {
    await t.pumpWidget(_wrap(BotConfigStatus.invalid, null));
    await t.pumpAndSettle();
    expect(find.textContaining('khong hop le'), findsWidgets);
  });

  testWidgets('3. configured -> nhan da cau hinh', (WidgetTester t) async {
    await t.pumpWidget(_wrap(BotConfigStatus.configured, null));
    await t.pumpAndSettle();
    expect(find.textContaining('da cau hinh'), findsWidgets);
  });

  testWidgets('5. o nhap token co obscureText == true', (WidgetTester t) async {
    await t.pumpWidget(_wrap(BotConfigStatus.notConfigured, null));
    await t.pumpAndSettle();
    final Iterable<TextField> fields =
        t.widgetList<TextField>(find.byType(TextField));
    expect(fields.any((TextField f) => f.obscureText), isTrue);
  });

  testWidgets('4. nhan kiem tra ket noi -> getMe duoc goi', (WidgetTester t) async {
    final FakeClient c = FakeClient();
    await t.pumpWidget(_wrap(BotConfigStatus.configured, c));
    await t.pumpAndSettle();
    expect(c.getMeCount, 0); // chua nhan thi chua goi
    await t.tap(find.byIcon(Icons.wifi_tethering));
    await t.pumpAndSettle();
    expect(c.getMeCount, 1);
    expect(find.textContaining('Ket noi thanh cong'), findsWidgets);
  });

  testWidgets('6. KHONG co token nao hien thi tren man hinh', (WidgetTester t) async {
    // Token gia - neu man hinh hien thi token, ca nay se do.
    const String fakeToken = '0000000000:FAKETOKENFORTESTONLYNOTREAL';
    await t.pumpWidget(_wrap(BotConfigStatus.configured, null));
    await t.pumpAndSettle();
    expect(find.text(fakeToken), findsNothing);
    expect(find.textContaining('0000000000'), findsNothing);
  });
}
