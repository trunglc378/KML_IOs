import 'package:flutter_test/flutter_test.dart';

import 'package:kml_ios/core/notify/telegram_message_builder.dart';

void main() {
  const TelegramMessageBuilder b = TelegramMessageBuilder();

  group('buildHeader', () {
    test('1. du bon dong, dung thu tu', () {
      final String h = b.buildHeader(
        deviceId: 'ios-dev-001',
        sessionId: 'SES-001',
        collectedAt: DateTime.utc(2026, 9, 25, 8, 0, 0),
        sentAt: DateTime.utc(2026, 9, 25, 8, 0, 7),
        payloadKind: 'location',
        recordCount: 12,
      );
      final List<String> lines = h.trim().split('\n');
      expect(lines[0], contains('platform=ios'));
      expect(lines[0], contains('deviceId=ios-dev-001'));
      expect(lines[1], contains('SES-001'));
      expect(lines[2], contains('2026-09-25T08:00:00Z'));
      expect(lines[3], contains('location'));
    });

    test('2. co chi so phan khi truyen partIndex/partTotal', () {
      final String h = b.buildHeader(
        deviceId: 'd', sessionId: 's',
        collectedAt: DateTime.utc(2026), sentAt: DateTime.utc(2026),
        payloadKind: 'location', recordCount: 5,
        partIndex: 2, partTotal: 5,
      );
      expect(h, contains('[Phan 2/5]'));
    });

    test('3. KHONG co chi so phan khi khong truyen', () {
      final String h = b.buildHeader(
        deviceId: 'd', sessionId: 's',
        collectedAt: DateTime.utc(2026), sentAt: DateTime.utc(2026),
        payloadKind: 'location', recordCount: 5,
      );
      expect(h, isNot(contains('[Phan')));
    });

    test('4. deviceId, sessionId, payloadKind xuat hien dung', () {
      final String h = b.buildHeader(
        deviceId: 'dev-XYZ', sessionId: 'SES-ABC',
        collectedAt: DateTime.utc(2026), sentAt: DateTime.utc(2026),
        payloadKind: 'contacts', recordCount: 3,
      );
      expect(h, contains('dev-XYZ'));
      expect(h, contains('SES-ABC'));
      expect(h, contains('contacts'));
    });
  });

  group('escapeHtml', () {
    test('5. dau &', () {
      expect(TelegramMessageBuilder.escapeHtml('&'), '&amp;');
    });
    test('6. the HTML', () {
      expect(TelegramMessageBuilder.escapeHtml('<b>'), '&lt;b&gt;');
    });
    test('7. thu tu escape dung', () {
      expect(TelegramMessageBuilder.escapeHtml('A & B < C'),
          'A &amp; B &lt; C');
    });
    test('8. khong escape hai lan', () {
      expect(TelegramMessageBuilder.escapeHtml('&lt;'), '&amp;lt;');
    });
  });

  group('splitIntoParts', () {

    String hdr(int i, int n) => 'H$i/$n\n';
    test('9. mot ban ghi ngan, chi so 1/1', () {
      final List<String> p = b.splitIntoParts(
        records: <String>['aaa'],
        headerBuilder: hdr,
        maxLength: 4096,
      );
      expect(p.length, 1);
      expect(p.first, contains('H1/1'));
    });

    test('10. chi so dung o MOI phan', () {
      final List<String> recs =
          List<String>.generate(10, (int i) => 'ban-ghi-');
      final List<String> p = b.splitIntoParts(
        records: recs, headerBuilder: hdr, maxLength: 40,
      );
      expect(p.length, greaterThan(1));
      for (int i = 0; i < p.length; i++) {
        expect(p[i], contains('H${i + 1}/${p.length}'));
      }
    });

    test('11. KHONG cat giua ban ghi', () {
      final List<String> recs = <String>[
        'aaa1', 'bbb2', 'ccc3', 'ddd4', 'eee5',
        'fff6', 'ggg7', 'hhh8', 'iii9', 'jjj10',
      ];
      final List<String> p = b.splitIntoParts(
        records: recs, headerBuilder: hdr, maxLength: 40,
      );
      final List<String> collected = <String>[];
      for (final String part in p) {
        final List<String> body = part.split('\n');
        for (int i = 1; i < body.length; i++) {
          if (body[i].isNotEmpty) collected.add(body[i]);
        }
      }
      expect(collected, recs);
    });

    test('12. ban ghi don le dai hon maxLength', () {
      final List<String> oversize = <String>[];
      final List<String> p = b.splitIntoParts(
        records: <String>['short', 'z' * 500, 'short2'],
        headerBuilder: hdr,
        maxLength: 100,
        onOversizeRecord: (int i, int len) => oversize.add(i.toString()),
      );
      expect(oversize.length, 1);
      bool found = false;
      for (final String part in p) {
        if (part.contains('z' * 500)) found = true;
      }
      expect(found, isTrue);
    });
  });

  group('bien', () {
    test('13. ban ghi chua ky tu HTML', () {
      const String raw = 'Ten & Co <email>'; 
      final String esc = TelegramMessageBuilder.escapeHtml(raw);
      expect(esc, 'Ten &amp; Co &lt;email&gt;');
    });

    test('14. tieng Viet co dau, dem theo ky tu', () {
      const String vn = 'Nguyen Van A'; 
      final String esc = TelegramMessageBuilder.escapeHtml(vn);
      expect(esc.length, vn.length);
    });

    test('15. danh sach rong, khong crash', () {
    String hdr(int i, int n) => 'H$i/$n\n';
      final List<String> p = b.splitIntoParts(
        records: <String>[], headerBuilder: hdr, maxLength: 4096,
      );
      expect(p.length, 1);
      expect(p.first, contains('H1/1'));
    });
  });
}
