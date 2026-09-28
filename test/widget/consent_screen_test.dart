import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kml_ios/features/consent/presentation/consent_screen.dart';

Widget _wrap(VoidCallback onAccepted) {
  return MaterialApp(
    home: ConsentScreen(onConsentAccepted: onAccepted),
  );
}

void main() {
  testWidgets('7. man hinh co chu Telegram', (WidgetTester t) async {
    await t.pumpWidget(_wrap(() {}));
    await t.pumpAndSettle();
    expect(find.textContaining('Telegram'), findsWidgets);
  });

  testWidgets('8. neu ro du lieu gui toi ben thu ba', (WidgetTester t) async {
    await t.pumpWidget(_wrap(() {}));
    await t.pumpAndSettle();
    expect(find.textContaining('ben thu ba'), findsWidgets);
  });

  testWidgets('9. consent render TRUOC khi quyen duoc yeu cau',
      (WidgetTester t) async {
    int acceptedCount = 0;
    await t.pumpWidget(_wrap(() => acceptedCount++));
    await t.pumpAndSettle();
    // Man hinh da render, nhung callback CHUA duoc goi -
    // nghia la quyen chua duoc xin.
    expect(find.textContaining('Telegram'), findsWidgets);
    expect(acceptedCount, 0);
    // Sau khi nguoi dung nhan nut thi callback moi chay, va buoc xin quyen
    // (do nguoi goi thuc hien) moi bat dau.
    await t.tap(find.byType(ElevatedButton));
    await t.pumpAndSettle();
    expect(acceptedCount, 1);
  });
}
