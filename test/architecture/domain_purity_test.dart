import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ca kiem thu TC-IO-NFR-11 - tang Domain thuan khiet.
///
/// Day KHONG phai ca chay thu: prompt Muc 15.4 ghi ro kha nang bao tri duoc
/// kiem chung bang RA SOAT IMPORT. Ca nay doc truc tiep ma nguon trong
/// `lib/features/**/domain/**` va khang dinh khong co import bi cam.
///
/// Quy tac trung voi tooling/check_domain_purity.dart (Muc 16.3):
/// tang Domain KHONG duoc import
///   - dio
///   - bat ky file nao trong core/network/ hoac core/notify/
///   - telegram_client.dart, telegram_result_sender.dart,
///     telegram_message_builder.dart, send_result.dart
///   - token_store.dart, telegram_config.dart
///   - flutter_secure_storage, sqflite, shared_preferences

/// Mot quy tac import bi cam. Giu dung thu tu va ly do nhu script.
class _Forbidden {
  _Forbidden(this.rule, this.reason) : pattern = RegExp(rule);

  final String rule;
  final RegExp pattern;
  final String reason;
}

const List<String> _expectedRules = <String>[
  r'^package:dio/',
  r'(^|/)core/network/',
  r'(^|/)core/notify/',
  r'telegram_client\.dart$',
  r'telegram_result_sender\.dart$',
  r'telegram_message_builder\.dart$',
  r'(^|/)send_result\.dart$',
  r'(^|/)token_store\.dart$',
  r'telegram_config\.dart$',
  r'^package:flutter_secure_storage/',
  r'^package:sqflite/',
  r'^package:shared_preferences/',
];

final List<_Forbidden> _forbidden = <_Forbidden>[
  _Forbidden(r'^package:dio/', 'Domain khong duoc dung dio.'),
  _Forbidden(r'(^|/)core/network/', 'Domain khong duoc import core/network.'),
  _Forbidden(r'(^|/)core/notify/', 'Domain khong duoc import core/notify.'),
  _Forbidden(r'telegram_client\.dart$', 'Domain khong duoc biet TelegramClient.'),
  _Forbidden(
    r'telegram_result_sender\.dart$',
    'Domain khong duoc biet TelegramResultSender.',
  ),
  _Forbidden(
    r'telegram_message_builder\.dart$',
    'Domain khong duoc biet TelegramMessageBuilder.',
  ),
  _Forbidden(r'(^|/)send_result\.dart$', 'Domain khong duoc biet SendResult.'),
  _Forbidden(r'(^|/)token_store\.dart$', 'Domain khong duoc biet TokenStore.'),
  _Forbidden(r'telegram_config\.dart$', 'Domain khong duoc biet TelegramConfig.'),
  _Forbidden(
    r'^package:flutter_secure_storage/',
    'Domain khong duoc dung flutter_secure_storage.',
  ),
  _Forbidden(r'^package:sqflite/', 'Domain khong duoc dung sqflite.'),
  _Forbidden(
    r'^package:shared_preferences/',
    'Domain khong duoc dung shared_preferences.',
  ),
];

/// Bat dong `import '...';` hoac `export '...';`.
final RegExp _importLine = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');

/// File thuoc tang Domain khi duong dan chua `/domain/` (Muc 3.1).
bool _isDomainPath(String path) =>
    path.replaceAll(r'\', '/').contains('/domain/');

/// Tra ve cac dong import vi pham trong mot doan ma nguon.
List<int> _violationLines(String source) {
  final List<int> lines = <int>[];
  final List<String> rows = source.split('\n');
  for (int i = 0; i < rows.length; i++) {
    final Match? m = _importLine.firstMatch(rows[i]);
    if (m == null) continue;
    final String target = m.group(1)!;
    if (_forbidden.any((_Forbidden f) => f.pattern.hasMatch(target))) {
      lines.add(i + 1);
    }
  }
  return lines;
}

void main() {
  /// Thu muc goc cua du an: `flutter test` chay voi cwd la goc du an.
  final Directory libDir = Directory('${Directory.current.path}/lib');

  /// Tat ca file .dart trong `lib/features/**/domain/**`.
  List<File> domainFiles() {
    if (!libDir.existsSync()) return <File>[];
    return libDir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .where((File f) => _isDomainPath(f.path))
        .toList()
      ..sort((File a, File b) => a.path.compareTo(b.path));
  }

  group('TC-IO-NFR-11 - tang Domain thuan khiet', () {
    test('1. nhan dien dung file thuoc tang Domain', () {
      expect(_isDomainPath('lib/features/sync/domain/entity.dart'), isTrue);
      // Duong dan Windows dung dau \\ nguoc van phai nhan dien duoc.
      expect(_isDomainPath(r'lib\features\sync\domain\entity.dart'), isTrue);
      expect(_isDomainPath('lib/features/sync/data/queue.dart'), isFalse);
      expect(_isDomainPath('lib/core/network/telegram_client.dart'), isFalse);
      // Chuoi 'domain' tran, khong phai thu muc, khong duoc tinh.
      expect(_isDomainPath('lib/features/domainless/thing.dart'), isFalse);
    });

    test('2. bang quy tac khop voi tooling/check_domain_purity.dart', () async {
      // Doc script de bao dam hai noi khong lech nhau ve tap quy tac cam.
      final File script = File(
        '${Directory.current.path}/tooling/check_domain_purity.dart',
      );
      expect(script.existsSync(), isTrue,
          reason: 'Thieu tooling/check_domain_purity.dart');
      final String src = await script.readAsString();
      for (final String rule in _expectedRules) {
        expect(
          src.contains(rule),
          isTrue,
          reason: 'Script thieu quy tac: $rule',
        );
      }
    });

    test('3. bat duoc import bi cam (khop mau)', () {
      const String dirty = "import 'package:dio/dio.dart';\n"
          "import '../core/network/telegram_client.dart';\n"
          "import 'package:flutter_secure_storage/flutter_secure_storage.dart';\n";
      expect(_violationLines(dirty), <int>[1, 2, 3]);
    });

    test('4. KHONG bao dong gia voi import hop le', () {
      const String clean = "import 'dart:async';\n"
          "import 'package:meta/meta.dart';\n"
          "import '../data/queue_row.dart';\n"
          "// import 'package:dio/dio.dart'; <- bi comment, khong tinh\n";
      expect(_violationLines(clean), isEmpty);
    });

    test('5. moi file trong lib/features/**/domain/** deu sach', () {
      final List<File> files = domainFiles();
      final List<String> dirty = <String>[];
      for (final File f in files) {
        final List<int> bad = _violationLines(f.readAsStringSync());
        if (bad.isNotEmpty) {
          dirty.add('${f.path}: dong ${bad.join(', ')}');
        }
      }
      expect(
        dirty,
        isEmpty,
        reason: 'Tang Domain vi pham ranh gioi tang:\n${dirty.join('\n')}',
      );
      // Ghi ro so file da ra soat de tranh truong hop "xanh gia" do quet sai.
      // ignore: avoid_print
      print('[TC-IO-NFR-11] Da ra soat ${files.length} file domain/.');
    });

    test('6. quet toan lib/ - bat ca file dat sai thu muc', () {
      final List<String> offenders = <String>[];
      if (libDir.existsSync()) {
        for (final FileSystemEntity e
            in libDir.listSync(recursive: true, followLinks: false)) {
          if (e is! File || !e.path.endsWith('.dart')) continue;
          if (!_isDomainPath(e.path)) continue;
          if (_violationLines(e.readAsStringSync()).isNotEmpty) {
            offenders.add(e.path);
          }
        }
      }
      expect(offenders, isEmpty);
    });
  });
}


