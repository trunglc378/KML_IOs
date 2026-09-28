// Kiểm tra tầng Domain thuần khiết — TC-IO-NFR-11 / ràng buộc Mục 1.8.
//
// Chạy: dart run tooling/check_domain_purity.dart
// Thoát mã 0 nếu sạch; thoát mã 1 nếu Domain import lớp gửi kết quả.
//
// QUY TẮC (Mục 16.3): tầng Domain KHÔNG được import
//   - dio (HTTP)
//   - bất kỳ file nào trong core/network/ hoặc core/notify/
//   - telegram_client.dart, telegram_result_sender.dart,
//     telegram_message_builder.dart, send_result.dart
//   - flutter_secure_storage, sqflite, shared_preferences
//
// Đây là ca kiểm tra BẰNG RÀ SOÁT IMPORT, không phải ca chạy thử
// (prompt Mục 15.4). Script này là công cụ; ca kiểm thử tương ứng nằm ở
// test/architecture/domain_purity_test.dart.
import 'dart:io';

/// Một quy tắc import bị cấm.
class ForbiddenImport {
  ForbiddenImport(this.rule, this.reason) : pattern = RegExp(rule);

  final String rule;
  final RegExp pattern;
  final String reason;
}

/// Các quy tắc cấm. Mẫu so khớp với phần đường dẫn trong `import '...'`.
final List<ForbiddenImport> forbiddenImports = <ForbiddenImport>[
  ForbiddenImport(
    r'^package:dio/',
    'Domain không được dùng dio — nghiệp vụ thuần, không phụ thuộc HTTP.',
  ),
  ForbiddenImport(
    r'(^|/)core/network/',
    'Domain không được import core/network (lớp gửi kết quả).',
  ),
  ForbiddenImport(
    r'(^|/)core/notify/',
    'Domain không được import core/notify (lớp gửi kết quả).',
  ),
  ForbiddenImport(
    r'telegram_client\.dart$',
    'Domain không được biết tới TelegramClient.',
  ),
  ForbiddenImport(
    r'telegram_result_sender\.dart$',
    'Domain không được biết tới TelegramResultSender.',
  ),
  ForbiddenImport(
    r'telegram_message_builder\.dart$',
    'Domain không được biết tới TelegramMessageBuilder.',
  ),
  ForbiddenImport(
    r'(^|/)send_result\.dart$',
    'Domain không được biết tới SendResult — đây là kiểu của lớp gửi.',
  ),
  ForbiddenImport(
    r'(^|/)token_store\.dart$',
    'Domain không được biết tới TokenStore.',
  ),
  ForbiddenImport(
    r'telegram_config\.dart$',
    'Domain không được biết tới TelegramConfig.',
  ),
  ForbiddenImport(
    r'^package:flutter_secure_storage/',
    'Domain không được dùng flutter_secure_storage.',
  ),
  ForbiddenImport(
    r'^package:sqflite/',
    'Domain không được dùng sqflite — Domain không biết gì về lưu trữ.',
  ),
  ForbiddenImport(
    r'^package:shared_preferences/',
    'Domain không được dùng shared_preferences.',
  ),
];

/// Mẫu bắt dòng `import '...';` hoặc `export '...';`.
final RegExp importLine = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''');

/// Kiểm tra một file Dart có phải file trong tầng Domain không.
/// Cấu trúc bắt buộc: `lib/features/<feature>/domain/...`.
bool isDomainFile(String relativePath) =>
    relativePath.replaceAll(r'\', '/').contains('/domain/');

/// Tìm các import bị cấm trong một đoạn nội dung file.
/// Trả về danh sách mô tả vi phạm, mỗi phần tử gồm số dòng và lý do.
List<ImportViolation> findViolationsInSource(String source) {
  final List<ImportViolation> found = <ImportViolation>[];
  final List<String> lines = source.split('\n');

  for (int i = 0; i < lines.length; i++) {
    final RegExpMatch? m = importLine.firstMatch(lines[i]);
    if (m == null) continue;

    final String target = m.group(1)!;
    for (final ForbiddenImport f in forbiddenImports) {
      if (f.pattern.hasMatch(target)) {
        found.add(
          ImportViolation(
            line: i + 1,
            target: target,
            rule: f.rule,
            reason: f.reason,
          ),
        );
      }
    }
  }
  return found;
}

/// Một vi phạm ranh giới tầng.
class ImportViolation {
  const ImportViolation({
    required this.line,
    required this.target,
    required this.rule,
    required this.reason,
  });

  final int line;
  final String target;
  final String rule;
  final String reason;
}

/// Kết quả kiểm tra một file.
class FileCheckResult {
  const FileCheckResult(this.relativePath, this.violations);

  final String relativePath;
  final List<ImportViolation> violations;

  bool get isClean => violations.isEmpty;
}

/// Kiểm tra toàn bộ file trong `lib/features/**/domain/**`.
Future<List<FileCheckResult>> checkProject(Directory libDir) async {
  final List<FileCheckResult> results = <FileCheckResult>[];

  await for (final FileSystemEntity entity
      in libDir.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.endsWith('.dart')) continue;

    final String rel = entity.path.replaceAll('\\', '/');
    if (!isDomainFile(rel)) continue;

    final String source = await entity.readAsString();
    results.add(
      FileCheckResult(_relativeTo(libDir.path, entity.path), findViolationsInSource(source)),
    );
  }

  results.sort((FileCheckResult a, FileCheckResult b) =>
      a.relativePath.compareTo(b.relativePath));
  return results;
}

String _relativeTo(String root, String path) {
  final String r = root.replaceAll('\\', '/').replaceAll(RegExp(r'/$'), '');
  final String p = path.replaceAll('\\', '/');
  return p.startsWith('$r/') ? p.substring(r.length + 1) : p;
}

Future<int> main(List<String> args) async {
  final Directory lib = Directory('${Directory.current.path}/lib');
  if (!await lib.exists()) {
    stdout.writeln('[LỖI] Không tìm thấy thư mục lib/.');
    return 1;
  }

  final List<FileCheckResult> results = await checkProject(lib);
  final List<FileCheckResult> dirty =
      results.where((FileCheckResult r) => !r.isClean).toList();

  stdout.writeln('Đã kiểm tra ${results.length} file trong các thư mục domain/.');
  if (dirty.isEmpty) {
    stdout.writeln('[ĐẠT] Tầng Domain thuần khiết (TC-IO-NFR-11).');
    return 0;
  }

  stdout.writeln('');
  stdout.writeln('[KHÔNG ĐẠT] Tầng Domain vi phạm ranh giới tầng:');
  for (final FileCheckResult r in dirty) {
    for (final ImportViolation v in r.violations) {
      stdout.writeln('  ${r.relativePath}:${v.line}  → ${v.target}');
      stdout.writeln('      Lý do: ${v.reason}');
    }
  }
  stdout.writeln('');
  stdout.writeln('Sửa: chuyển phụ thuộc vào tầng Data, Domain chỉ giữ interface.');
  return 1;
}
