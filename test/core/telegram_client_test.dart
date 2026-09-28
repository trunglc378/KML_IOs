import 'dart:convert';
import 'dart:typed_data';  
  
import 'package:dio/dio.dart';  
import 'package:flutter_test/flutter_test.dart';  
  
import 'package:kml_ios/core/network/telegram_client.dart';  
import 'package:kml_ios/core/notify/send_result.dart';  
import 'package:kml_ios/core/security/token_store.dart';  
  
/// Adapter gia: tra phan hoi dinh san, khong goi mang.  
class FakeAdapter implements HttpClientAdapter {  
  FakeAdapter(this.statusCode, this.body);  
  
  final int statusCode;  
  final Object body;  
  int callCount = 0;
  bool throwOnFetch = false;  
  
  @override  
  Future<ResponseBody> fetch(  
    RequestOptions options,  
    Stream<Uint8List>? requestStream,  
    Future<void>? cancelFuture,  
  ) async {  
    callCount++;
    if (throwOnFetch) {
      throw DioException(requestOptions: options, type: DioExceptionType.connectionTimeout);
    }  
    return ResponseBody.fromString(  
      body is String ? body as String : jsonEncode(body),  
      statusCode,  
      headers: <String, List<String>>{  
        Headers.contentTypeHeader: [Headers.jsonContentType],  
      },  
    );  
  }  
  
  @override  
  void close({bool? force}) {}  
}  
  
/// Tao client voi adapter gia va token cho truoc.  
Future<(TelegramClient, FakeAdapter)> makeClient(  
  int statusCode,  
  Object body, {  
  String? token = '8920168927:AAEabcXYZsecretvalue1234567890',  
}) async {  
  final Dio dio = TelegramClient.buildDio();  
  final FakeAdapter ad = FakeAdapter(statusCode, body);  
  dio.httpClientAdapter = ad;  
  final TokenStore ts = _FakeTokenStore(token);  
  return (TelegramClient(dio, ts), ad);  
}  
  
/// TokenStore gia: khong dung Keychain (khong can thiet bi.)  
class _FakeTokenStore implements TokenStore {  
  _FakeTokenStore(this._token);  
  final String? _token;  
  @override  
  Future<String?> readBotToken() async => _token;  
  @override  
  Future<String?> readChatId() async => null;  
  @override  
  Future<void> writeBotToken(String t) async {}  
  @override  
  Future<void> writeChatId(String c) async {}  
  @override  
  Future<void> clear() async {}  
  @override  
  Future<bool> hasCredentials() async => _token != null;  
  @override  
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);  
}  
  
/// Tao client voi adapter gia va token cho truoc.  
void main() {  
  group('TelegramClient - bang anh xa loi', () {  
    test('1. ok:true -> success, messageId dung', () async {  
      final r = await makeClient(200, <String, dynamic>{  
        'ok': true, 'result': <String, dynamic>{'message_id': 4242},  
      });  
      final SendResult s = await r.$1.sendMessage(chatId: '5887530234', text: 'x');  
      expect(s.status, SendStatus.success);  
      expect(s.messageId, 4242);  
    });  
  
    test('2. timeout -> retryable', () async {  
      final r = await makeClient(200, '{}');  
      r.$2.throwOnFetch = true;  
      final SendResult s = await r.$1.sendMessage(chatId: '5887530234', text: 'x');  
      expect(s.status, SendStatus.retryable);  
    });  
  
    test('3. HTTP 429 + retry_after 7 -> retryable, 7 giay', () async {  
      final r = await makeClient(429, <String, dynamic>{  
        'ok': false, 'error_code': 429,  
        'parameters': <String, dynamic>{'retry_after': 7},  
      });  
      final SendResult s = await r.$1.sendMessage(chatId: '5887530234', text: 'x');  
      expect(s.status, SendStatus.retryable);  
      expect(s.retryAfter?.inSeconds, 7);  
    });  
  
    test('4. HTTP 500 -> retryable', () async {  
      final r = await makeClient(500, 'loi may chu');  
      final SendResult s = await r.$1.sendMessage(chatId: '5887530234', text: 'x');  
      expect(s.status, SendStatus.retryable);  
    });  
  
    test('5. HTTP 401 -> fatalAuth', () async {  
      final r = await makeClient(401, '{}');  
      final SendResult s = await r.$1.sendMessage(chatId: '5887530234', text: 'x');  
      expect(s.status, SendStatus.fatalAuth);  
      expect(s.isTerminal, isTrue);  
    });  
  
    test('6. HTTP 400 -> fatalConfig', () async {  
      final r = await makeClient(400, '{}');  
      final SendResult s = await r.$1.sendMessage(chatId: '5887530234', text: 'x');  
      expect(s.status, SendStatus.fatalConfig);  
      expect(s.isTerminal, isTrue);  
    });  
  
    test('7. HTTP 403 -> fatalConfig', () async {  
      final r = await makeClient(403, '{}');  
      final SendResult s = await r.$1.sendMessage(chatId: '5887530234', text: 'x');  
      expect(s.status, SendStatus.fatalConfig);  
    });  
  
    test('8. ok:false chat not found -> fatalConfig', () async {  
      final r = await makeClient(400, <String, dynamic>{  
        'ok': false, 'error_code': 400,  
        'description': 'Bad Request: chat not found',  
      });  
      final SendResult s = await r.$1.sendMessage(chatId: '5887530234', text: 'x');  
      expect(s.status, SendStatus.fatalConfig);  
    });  
  
    test('9. HTTP 413 -> oversize', () async {  
      final r = await makeClient(413, '{}');  
      final SendResult s = await r.$1.sendMessage(chatId: '5887530234', text: 'x');  
      expect(s.status, SendStatus.oversize);  
    });  
  
    test('10. token null -> fatalAuth, KHONG goi API', () async {  
      final r = await makeClient(200, '{}', token: null);  
      final SendResult s = await r.$1.sendMessage(chatId: '5887530234', text: 'x');  
      expect(s.status, SendStatus.fatalAuth);  
      expect(r.$2.callCount, 0);  
    });  
  
    test('11. safeUrl che token trong log', () async {  
      const String tok = '8920168927:AAEabcXYZsecretvalue1234567890';  
      final String u = TelegramClient.safeUrl(  
        'https://api.telegram.org/bot' + tok + '/sendMessage');  
      expect(u.contains('AAEabcXYZsecretvalue1234567890'), isFalse);  
      expect(u.contains('8920168927:***'), isTrue);  
    });  
  
    test('12. description khong chua token', () async {  
      final r = await makeClient(400, <String, dynamic>{  
        'ok': false, 'error_code': 400,  
        'description': 'Bad Request',  
      });  
      final SendResult s = await r.$1.sendMessage(chatId: '5887530234', text: 'x');  
      expect(s.description, isNotNull);  
      expect(s.description!.contains('8920168927:'), isFalse);  
    });  
  });  
}  
