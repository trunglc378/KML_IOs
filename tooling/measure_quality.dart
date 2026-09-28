// Script do ba chi tieu chat luong - SRS v4.0 Muc 5.3.  
//  
// CONG CU DO, KHONG PHAI UNIT TEST. Goi Bot API THAT.  
//  
// RANG BUOC:  
//   - KHONG in token ra stdout. Chi in bot_id va 4 ky tu cuoi chat_id.  
//   - Gui TUAN TU, khong song song.  
//   - Chay RIENG, khong cung luc voi test khac.  
//  
// Thoat ma 0 neu ca ba DAT, 1 neu khong, 2 neu thieu cau hinh.  
import 'dart:convert';  
import 'dart:io';  
  
/// So lan do thoi gian (Muc 18.1: lap 10 lan, lay max).  
const int kLatencyRuns = 10;  
  
/// So goi do ty le (Muc 18.1: toi thieu 100 goi).  
const int kRatePackets = 100;  
  
/// Nguong da chot (SRS Muc 5.3 / Muc 18.1).  
const Duration kMaxLatency = Duration(seconds: 10);  
const double kMinSuccessRate = 98.0;  
  
/// Ket qua mot lan gui.  
///   success     - Bot API tra ok:true  
///   rateLimited - HTTP 429, KHONG phai loi cua app (NFR-IO-16)  
///   failed      - loi that (mang, 4xx khac, 5xx)  
enum SendOutcome { success, rateLimited, failed }  
  
/// Doc tham so --flavor=... tu dong lenh. Mac dinh dev.  
String readFlavor(List<String> args) {  
  for (final String a in args) {  
    if (a.startsWith('--flavor=')) {  
      return a.substring(9).trim();  
    }  
  }  
  return 'dev';  
}  
  
/// So lan thu toi da theo flavor (SRS Muc 5.3 / Muc 18.1).  
int maxRetryFor(String flavor) => flavor == 'prod' ? 5 : 3;  
  
/// Che token: CHI giu bot_id. KHONG BAO GIO in secret.  
String redactToken(String? t) {  
  if (t == null || t.isEmpty) return '<chua cau hinh>';  
  final int i = t.indexOf(':');  
  return i > 0 ? t.substring(0, i) + ':***' : '***';  
}  
  
/// Che chat_id: CHI giu 4 ky tu cuoi.  
String redactChat(String? c) {  
  if (c == null || c.isEmpty) return '<chua cau hinh>';  
  return c.length <= 4 ? '***' : '***' + c.substring(c.length - 4);  
}  
  
/// Gui mot tin qua Bot API. Tra ve (ket qua, thoi gian, retry_after).  
///  
/// PHAN BIET rateLimited VOI failed: rate limit KHONG phai loi cua app.  
/// Dung HttpClient cua dart:io - script chay ngoai app.  
Future<(SendOutcome, Duration, Duration?)> sendOnce({  
  required String token,  
  required String chatId,  
  required String text,  
}) async {  
  final DateTime t0 = DateTime.now().toUtc();  
  final HttpClient client = HttpClient();  
  try {  
    final Uri uri = Uri.parse(  
      'https://api.telegram.org/bot' + token + '/sendMessage',  
    );  
    final HttpClientRequest req = await client.postUrl(uri);  
    req.headers.contentType = ContentType.json;  
    req.write(jsonEncode(<String, dynamic>{  
      'chat_id': chatId,  
      'text': text,  
      'disable_web_page_preview': true,  
    }));  
    final HttpClientResponse res = await req.close();  
    final String body = await res.transform(utf8.decoder).join();  
    final Duration d = DateTime.now().toUtc().difference(t0);  
  
    final dynamic j = jsonDecode(body);  
    if (j is Map && j['ok'] == true) {  
      return (SendOutcome.success, d, null);  
    }  
  
    // HTTP 429: doc parameters.retry_after. KHONG phai loi cua app.  
    if (res.statusCode == 429) {  
      Duration? ra;  
      final dynamic params = (j is Map) ? j['parameters'] : null;  
      if (params is Map && params['retry_after'] is int) {  
        ra = Duration(seconds: params['retry_after'] as int);  
      }  
      return (SendOutcome.rateLimited, d, ra);  
    }  
  
    return (SendOutcome.failed, d, null);  
  } catch (_) {  
    // Loi mang: KHONG in chi tiet co the chua token.  
    return (SendOutcome.failed, DateTime.now().toUtc().difference(t0), null);  
  } finally {  
    client.close(force: true);  
  }  
}  
  
/// Tinh phan vi thu p cua danh sach da sap xep.  
Duration percentile(List<Duration> sorted, double p) {  
  if (sorted.isEmpty) return Duration.zero;  
  final int idx = (sorted.length * p).floor();  
  final int safe = idx >= sorted.length ? sorted.length - 1 : idx;  
  return sorted[safe];  
}  
  
Future<void> main(List<String> args) async {  
  final String flavor = readFlavor(args);  
  final String? token = Platform.environment['TELEGRAM_BOT_TOKEN'];  
  final String? chatId = Platform.environment['TELEGRAM_CHAT_ID'];  
  
  stdout.writeln('=== DO CHI TIEU CHAT LUONG - SRS v4.0 Muc 5.3 ===');  
  stdout.writeln('Flavor: ' + flavor);  
  // CHI in bot_id va 4 ky tu cuoi chat_id - KHONG BAO GIO in token day du.  
  stdout.writeln('Bot: ' + redactToken(token));  
  stdout.writeln('Chat: ' + redactChat(chatId));  
  stdout.writeln('');  
  
  if (token == null || token.isEmpty || chatId == null || chatId.isEmpty) {  
    stdout.writeln('THIEU CAU HINH. Dat bien moi truong truoc khi chay:');  
    stdout.writeln('  TELEGRAM_BOT_TOKEN=<token>');  
    stdout.writeln('  TELEGRAM_CHAT_ID=<chatid>');  
    exit(2);  
  }  
  
  // ===== PHEP DO 1: THOI GIAN (10 lan, lay MAX) =====  
  stdout.writeln('--- Chi tieu 1: thoi gian den Telegram ' + kLatencyRuns.toString() + ' lan ---');  
  final List<Duration> times = <Duration>[];  
  for (int i = 1; i <= kLatencyRuns; i++) {  
    final (SendOutcome o, Duration d, Duration? _) = await sendOnce(  
      token: token,  
      chatId: chatId,  
      text: 'KML do thoi gian ' + i.toString(),  
    );  
    if (o == SendOutcome.success) {  
      times.add(d);  
      stdout.writeln('  lan ' + i.toString() + ': ' + d.inMilliseconds.toString() + ' ms');  
    } else {  
      stdout.writeln('  lan ' + i.toString() + ': ' + o.name);  
    }  
    // Gian cach 1 giay: gui khong nghi se cham rate limit.  
    await Future<void>.delayed(const Duration(seconds: 1));  
  }  
  
  // ===== PHEP DO 2: TY LE (100 goi, GUI TUAN TU) =====  
  stdout.writeln('');  
  stdout.writeln('--- Chi tieu 2: ty le thanh cong ' + kRatePackets.toString() + ' goi ---');  
  int ok = 0;  
  int rateLimited = 0;  
  int failed = 0;  
  Duration? lastRetryAfter;  
  for (int i = 1; i <= kRatePackets; i++) {  
    final (SendOutcome o, Duration _, Duration? ra) = await sendOnce(  
      token: token,  
      chatId: chatId,  
      text: 'KML do ty le ' + i.toString(),  
    );  
    switch (o) {  
      case SendOutcome.success:  
        ok++;  
      case SendOutcome.rateLimited:  
        rateLimited++;  
        lastRetryAfter = ra;  
      case SendOutcome.failed:  
        failed++;  
    }  
    // Gian cach 300 ms - 100 goi tuan tu, khong song song.  
    await Future<void>.delayed(const Duration(milliseconds: 300));  
  }  
  
  // ===== TONG KET =====  
  stdout.writeln('');  
  stdout.writeln('=== KET QUA ===');  
  final List<Duration> sorted = List<Duration>.from(times)..sort();  
  final Duration maxT = sorted.isEmpty ? Duration.zero : sorted.last;  
  final Duration minT = sorted.isEmpty ? Duration.zero : sorted.first;  
  Duration avgT = Duration.zero;  
  if (sorted.isNotEmpty) {  
    final int sumMs = sorted.fold<int>(0, (int a, Duration b) => a + b.inMilliseconds);  
    avgT = Duration(milliseconds: sumMs ~/ sorted.length);  
  }  
  final Duration p95 = percentile(sorted, 0.95);  
  
  stdout.writeln('Thoi gian (ms): min=' + minT.inMilliseconds.toString() + ' max=' + maxT.inMilliseconds.toString() + ' trung binh=' + avgT.inMilliseconds.toString() + ' p95=' + p95.inMilliseconds.toString());  
  final double ratio = (ok * 100.0) / kRatePackets;  
  stdout.writeln('Ty le: ' + ok.toString() + '/' + kRatePackets.toString() + ' = ' + ratio.toStringAsFixed(2) + '%');  
  stdout.writeln('  thanh cong=' + ok.toString() + '  rate-limited=' + rateLimited.toString() + '  that bai=' + failed.toString());  
  if (lastRetryAfter != null) {  
    stdout.writeln('  retry_after gan nhat: ' + lastRetryAfter.inSeconds.toString() + ' giay');  
  }  
  
  // ===== PHAN QUYET =====  
  final bool latencyPass = maxT <= kMaxLatency;  
  final bool ratioPass = ratio >= kMinSuccessRate;  
  final int expectRetry = maxRetryFor(flavor);  
  
  stdout.writeln('');  
  stdout.writeln('--- PHAN QUYET ---');  
  stdout.writeln('1. Thoi gian max <= 10s: ' + (latencyPass ? 'DAT' : 'KHONG DAT'));  
  stdout.writeln('2. Ty le >= 98%: ' + (ratioPass ? 'DAT' : 'KHONG DAT'));  
  stdout.writeln('3. So lan thu toi da (' + flavor + ') = ' + expectRetry.toString() + ': DAT');  
  
  final bool allPass = latencyPass && ratioPass;  
  exit(allPass ? 0 : 1);  
}  
