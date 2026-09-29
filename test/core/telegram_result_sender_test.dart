import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:kml_ios/core/network/telegram_client.dart';
import 'package:kml_ios/core/notify/send_result.dart';
import 'package:kml_ios/core/notify/telegram_message_builder.dart';
import 'package:kml_ios/core/notify/telegram_result_sender.dart';
import 'package:kml_ios/core/security/token_store.dart';

/// Client gia: dem so lan goi, ghi lai phuong thuc, co hang doi ket qua.
class FakeClient implements TelegramClient {
  int callCount = 0;
  String? lastMethod;
  SendResult next = const SendResult(status: SendStatus.success, messageId: 1);
  final List<SendResult> queue = <SendResult>[];

  SendResult take() {
    if (queue.isNotEmpty) return queue.removeAt(0);
    return next;
  }

  @override
  Future<SendResult> sendMessage({
    required String chatId,
    required String text,
    String parseMode = 'HTML',
  }) async {
    callCount++;
    lastMethod = 'sendMessage';
    return take();
  }

  @override
  Future<SendResult> sendDocument({
    required String chatId,
    required String filePath,
    String? caption,
  }) async {
    callCount++;
    lastMethod = 'sendDocument';
    return take();
  }

  @override
  Future<SendResult> sendPhoto({
    required String chatId,
    required String filePath,
    String? caption,
  }) async {
    callCount++;
    lastMethod = 'sendPhoto';
    return take();
  }

  @override
  Future<bool> getMe() async => true;

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// TokenStore gia: tra gia tri cai san, khong cham Keychain.
class FakeTokenStore implements TokenStore {
  FakeTokenStore({this.chatId, this.token});
  String? chatId;
  String? token;

  @override
  Future<String?> readChatId() async => chatId;
  @override
  Future<String?> readBotToken() async => token;
  @override
  Future<void> writeBotToken(String t) async {}
  @override
  Future<void> writeChatId(String c) async {}
  @override
  Future<void> clear() async {}
  @override
  Future<bool> hasCredentials() async => token != null;
}

const String kValidToken = '0000000000:FAKE_TOKEN_FOR_TEST_ONLY_NOT_REAL';
const String kDevChatId = '5887530234';
const String kForeignChatId = '-9999999999';

(TelegramResultSender, FakeClient) makeSender({
  String? chatId = kDevChatId,
  String? token = kValidToken,
}) {
  final FakeClient c = FakeClient();
  final TelegramResultSender s = TelegramResultSender(
    client: c,
    tokenStore: FakeTokenStore(chatId: chatId, token: token),
    builder: const TelegramMessageBuilder(),
  );
  return (s, c);
}

Future<SendResult> callSend(
  TelegramResultSender s, {
  List<String>? records,
  String? filePath,
  String payloadKind = 'location',
}) {
  return s.send(
    sessionId: 'SES-1',
    deviceId: 'ios-dev-001',
    payloadKind: payloadKind,
    records: records ?? <String>['lat=1 lon=2'],
    filePath: filePath,
    collectedAt: DateTime.utc(2026, 9, 25, 8, 0, 0),
  );
}

void main() {
  group('cau hinh sai - KHONG phat sinh request', () {
    test('1. chat_id null -> fatalConfig, callCount == 0', () async {
      final r = makeSender(chatId: null);
      final SendResult res = await callSend(r.$1);
      expect(res.status, SendStatus.fatalConfig);
      expect(r.$2.callCount, 0);
    });

    test('2. chat_id ngoai whitelist -> blocked, callCount == 0', () async {
      final r = makeSender(chatId: kForeignChatId);
      final SendResult res = await callSend(r.$1);
      expect(res.status, SendStatus.blocked);
      expect(r.$2.callCount, 0);
    });

    test('3. token null -> fatalAuth, callCount == 0', () async {
      final r = makeSender(token: null);
      final SendResult res = await callSend(r.$1);
      expect(res.status, SendStatus.fatalAuth);
      expect(r.$2.callCount, 0);
    });

    test('4. cau hinh hop le -> callCount == 1, sendMessage', () async {
      final r = makeSender();
      final SendResult res = await callSend(r.$1);
      expect(res.status, SendStatus.success);
      expect(r.$2.callCount, 1);
      expect(r.$2.lastMethod, 'sendMessage');
    });
  });

  group('chon phuong thuc van ban', () {
    test('5. van ban ngan -> sendMessage', () async {
      final r = makeSender();
      await callSend(r.$1);
      expect(r.$2.lastMethod, 'sendMessage');
    });

    test('6. van ban dai (>4096) -> chia phan, sendMessage nhieu lan', () async {
      final List<String> big = List<String>.generate(
        400, (int i) => 'ban-ghi-$i');
      final r = makeSender();
      await callSend(r.$1, records: big);
      expect(r.$2.lastMethod, 'sendMessage');
      expect(r.$2.callCount, greaterThan(1));
    });
  });

  group('duong tep - chon anh vs tep', () {
    File makeFile(String name, int bytes) {
      final Directory d = Directory.systemTemp.createTempSync('kml7_');
      final File f = File(d.path + Platform.pathSeparator + name);
      f.writeAsBytesSync(List<int>.filled(bytes, 0));
      return f;
    }

    test('7. tep nho (<=50MB) -> sendDocument', () async {
      final File f = makeFile('small.bin', 100);
      final r = makeSender();
      await callSend(r.$1, records: <String>[], filePath: f.path);
      expect(r.$2.lastMethod, 'sendDocument');
      f.parent.deleteSync(recursive: true);
    });

    test('8. anh nho (<=10MB) -> sendPhoto', () async {
      final File f = makeFile('shot.png', 100);
      final r = makeSender();
      await callSend(r.$1, records: <String>[], filePath: f.path, payloadKind: 'screen');
      expect(r.$2.lastMethod, 'sendPhoto');
      f.parent.deleteSync(recursive: true);
    });

    test('9. tep vuot 50MB -> oversize, callCount == 0', () async {
      final File f = makeFile('big.bin', 51 * 1024 * 1024);
      final r = makeSender();
      final SendResult res = await callSend(r.$1, records: <String>[], filePath: f.path);
      expect(res.status, SendStatus.oversize);
      expect(r.$2.callCount, 0);
      f.parent.deleteSync(recursive: true);
    });
  });

  group('sendParts - dung o loi dau tien', () {
    Future<SendResult> runParts(FakeClient c, List<String> parts) {
      final TelegramResultSender s = TelegramResultSender(
        client: c,
        tokenStore: FakeTokenStore(chatId: kDevChatId, token: kValidToken),
        builder: const TelegramMessageBuilder(),
      );
      return s.sendParts(
        sessionId: 'SES-1',
        deviceId: 'ios-dev-001',
        payloadKind: 'location',
        parts: parts,
        collectedAt: DateTime.utc(2026, 9, 25),
      );
    }

    test('10. tat ca phan thanh cong -> callCount == so phan', () async {
      final FakeClient c = FakeClient();
      final SendResult res = await runParts(c, <String>['p1', 'p2', 'p3']);
      expect(res.status, SendStatus.success);
      expect(c.callCount, 3);
    });

    test('11. phan 2 retryable -> DUNG, callCount == 2', () async {
      final FakeClient c = FakeClient();
      c.queue.add(const SendResult(status: SendStatus.success, messageId: 1));
      c.queue.add(const SendResult(status: SendStatus.retryable, description: 'loi mang'));
      final SendResult res = await runParts(c, <String>['p1', 'p2', 'p3']);
      expect(res.status, SendStatus.retryable);
      expect(c.callCount, 2);
    });

    test('12. phan 2 fatalAuth -> DUNG, callCount == 2', () async {
      final FakeClient c = FakeClient();
      c.queue.add(const SendResult(status: SendStatus.success, messageId: 1));
      c.queue.add(const SendResult(status: SendStatus.fatalAuth, description: 'token hong'));
      final SendResult res = await runParts(c, <String>['p1', 'p2', 'p3']);
      expect(res.status, SendStatus.fatalAuth);
      expect(c.callCount, 2);
      expect(res.isTerminal, isTrue);
    });
  });
}
