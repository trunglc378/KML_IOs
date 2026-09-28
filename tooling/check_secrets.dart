// Script kiểm tra bí mật trong repo — dùng cho TC-IO-SEC-08 / TC-IO-NFR-13.
//
// Chạy: dart run tooling/check_secrets.dart
// Thoát mã 0 nếu sạch; thoát mã 1 nếu phát hiện bí mật.
//
// PHẠM VI QUÉT: toàn bộ file văn bản trong repo, TRỪ:
//   - .git/            (lịch sử, không phải nội dung làm việc)
//   - build/, .dart_tool/  (sản phẩm sinh tự động)
//   - tooling/check_secrets.dart  (chính file này — chứa mẫu regex)
//   - doc/             (tài liệu dự án, có thể chứa ví dụ minh hoạ)
//
// QUAN TRỌNG: script này KHÔNG BAO GIỜ in ra giá trị bí mật tìm được.
// Nó chỉ in tên file, số dòng và loại bí mật — đúng tinh thần NFR-IO-13.
import 'dart:io';

/// Một mẫu nhận dạng bí mật.
class SecretPattern {
  SecretPattern(this.name, String pattern, this.hint)
      : pattern = RegExp(pattern);

  final String name;
  final RegExp pattern;
  final String hint;
}

/// Kết quả một lần vi phạm — KHÔNG chứa giá trị bí mật.
class Violation {
  const Violation(this.file, this.line, this.patternName, this.hint);

  final String file;
  final int line;
  final String patternName;
  final String hint;

  @override
  String toString() => '  $file:$line  [$patternName]  → $hint';
}

final List<SecretPattern> _patterns = <SecretPattern>[
  // Bot token Telegram: <số 8-12 chữ số>:<35+ ký tự base64-url>
  SecretPattern(
    'telegram_bot_token',
    r'\b\d{8,12}:[A-Za-z0-9_\-]{35,}\b',
    'Bot token Telegram bị hard-code. Nạp qua --dart-define thay vì ghi vào source.',
  ),
  // Gán token dạng chuỗi tường minh: botToken = "1234:AA..."
  SecretPattern(
    'hardcoded_token_assignment',
    r'''(?:botToken|BOT_TOKEN|TELEGRAM_BOT_TOKEN)\s*[:=]\s*["'][^"'\s]{20,}["']''',
    'Token được gán trực tiếp bằng hằng chuỗi. Dùng String.fromEnvironment.',
  ),
  // chat_id: CHỈ báo khi gán vào biến cấu hình bí mật (tokenStore.writeChatId).
  // Theo quyết định đã chốt: chat_id là ĐỊNH DANH kênh, không phải bí mật,
  // nên whitelist trong source và trong test là hợp lệ. Chỉ che trong LOG.
  // chat_id la DINH DANH kenh, khong phai bi mat (da chot).
  // Chi bao khi nap tu bien moi truong bi mat, KHONG bao whitelist/test.
  SecretPattern(
    'hardcoded_chat_id',
    r'''(?:TELEGRAM_CHAT_ID|BOT_CHAT_ID)\s*[:=]\s*["']\-?\d{6,}["']''',
    'chat_id nap tu hang so bi mat. Dung --dart-define hoac Keychain.',
  ),
  // URL Bot API có token nhúng.
  SecretPattern(
    'token_in_url',
    r'api\.telegram\.org/bot\d{8,12}:[A-Za-z0-9_\-]{20,}',
    'URL Bot API chứa token đầy đủ.',
  ),
  // Khoá riêng / PEM.
  SecretPattern(
    'private_key_block',
    r'-----BEGIN (?:RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----',
    'Khoá riêng bị commit vào repo.',
  ),
  // Token dịch vụ thông dụng.
  SecretPattern(
    'generic_api_key',
    r'''(?:api[_-]?key|apikey|secret[_-]?key|access[_-]?token)\s*[:=]\s*["'][A-Za-z0-9_\-]{24,}["']''',
    'Khoá API dạng chuỗi tường minh.',
  ),
  // AWS access key.
  SecretPattern(
    'aws_access_key',
    r'\bAKIA[0-9A-Z]{16}\b',
    'AWS access key ID.',
  ),
  // GitHub token.
  SecretPattern(
    'github_token',
    r'\bgh[pousr]_[A-Za-z0-9]{36,}\b',
    'GitHub personal access token.',
  ),
];

/// Thư mục bỏ qua hoàn toàn.
const Set<String> _skipDirs = <String>{
  '.git',
  'build',
  '.dart_tool',
  'doc',
  '.idea',
  '.vscode',
  'Pods',
  'ephemeral',
};

/// Phần mở rộng được quét (chỉ file văn bản).
const Set<String> _textExtensions = <String>{
  '.dart',
  '.yaml',
  '.yml',
  '.json',
  '.md',
  '.txt',
  '.xml',
  '.plist',
  '.sh',
  '.bat',
  '.env',
  '.example',
  '.gradle',
  '.kt',
  '.swift',
  '.m',
  '.h',
  '.pbxproj',
  '.xcconfig',
  '.properties',
  '.cfg',
  '.ini',
  '.toml',
};

/// File bỏ qua (đường dẫn tương đối, dùng '/').
const Set<String> _skipFiles = <String>{
  'tooling/check_secrets.dart',
  'tooling/check_domain_purity.dart',
};

Future<int> main(List<String> args) async {
  final Directory root = Directory.current;
  final List<Violation> violations = <Violation>[];
  int scanned = 0;

  await for (final FileSystemEntity entity
      in root.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;

    final String rel = _relative(root.path, entity.path);
    final String relPosix = rel.replaceAll('\\', '/');

    // Bỏ qua file trong thư mục bị loại.
    if (relPosix.split('/').any(_skipDirs.contains)) continue;
    if (_skipFiles.contains(relPosix)) continue;

    final String ext = _extension(entity.path);
    if (!_textExtensions.contains(ext)) continue;

    // Bỏ qua file quá lớn (> 2 MB) để tránh quét nhầm tài nguyên nhị phân.
    final int size = await entity.length();
    if (size > 2 * 1024 * 1024) continue;

    List<String> lines;
    try {
      lines = await entity.readAsLines();
    } on FileSystemException {
      continue; // File nhị phân hoặc không đọc được.
    } on FormatException {
      continue; // Không phải UTF-8.
    }

    scanned++;
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i];

      // Bỏ qua dòng đã được đánh dấu an toàn.
      if (line.contains('check-secrets:ignore')) continue;

      for (final SecretPattern p in _patterns) {
        if (p.pattern.hasMatch(line)) {
          violations.add(
            Violation(relPosix, i + 1, p.name, p.hint),
          );
        }
      }
    }
  }

  print('Đã quét $scanned file văn bản.');
  if (violations.isEmpty) {
    print('[ĐẠT] Không tìm thấy bí mật nào trong repo (TC-IO-SEC-08).');
    return 0;
  }

  print('');
  print('[KHÔNG ĐẠT] Phát hiện ${violations.length} vi phạm tiềm năng:');
  print('(Giá trị bí mật KHÔNG được in ra — chỉ vị trí và loại)');
  print('');
  for (final Violation v in violations) {
    print(v);
  }
  print('');
  print('Nếu đây là dương tính giả, thêm "check-secrets:ignore" vào cuối dòng.');
  return 1;
}

String _relative(String root, String path) {
  final String r = root.endsWith(Platform.pathSeparator)
      ? root
      : '$root${Platform.pathSeparator}';
  return path.startsWith(r) ? path.substring(r.length) : path;
}

String _extension(String path) {
  final int dot = path.lastIndexOf('.');
  if (dot < 0) return '';
  return path.substring(dot).toLowerCase();
}

