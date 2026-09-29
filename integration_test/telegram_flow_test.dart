// Integration test - KML-iOS v4.0 kenh gui Telegram.  
//  
// Bon nhom ca theo KML-TEST-001 v4.0.  
//  
// PHAM VI:  
//   NHOM 1 (TC-IO-NOT-01 + TC-IO-13) - CAN THIET BI THAT  
//   NHOM 2 (TC-IO-NOT-03)             - chay duoc tren DESKTOP  
//   NHOM 3 (TC-IO-14)                 - CAN THIET BI THAT  
//   NHOM 4 (TC-IO-NOT-05)             - chay duoc tren DESKTOP  
//  
// Chay nhom 2 va 4 tren desktop:  
//   flutter test integration_test/telegram_flow_test.dart  
//  
// Chay nhom 1 va 3 tren thiet bi that:  
//   flutter test integration_test/telegram_flow_test.dart -d <device-id>  
//   (can cau hinh token + chat_id that qua man hinh /settings truoc)  
  
import 'package:flutter_test/flutter_test.dart';  
import 'package:sqflite_common_ffi/sqflite_ffi.dart';  
  
import 'package:kml_ios/core/constants/telegram_config.dart';  
import 'package:kml_ios/core/data/database.dart';  
import 'package:kml_ios/core/notify/send_result.dart';  
import 'package:kml_ios/core/notify/telegram_dispatcher.dart';  
import 'package:kml_ios/core/notify/telegram_result_sender.dart';  
import 'package:kml_ios/features/sync/data/telegram_queue.dart';  
  
/// Sender gia cho nhom 2 va 4 - tra ket qua cai san.  
class FakeSender implements TelegramResultSender {  
  FakeSender(this._results);  
  final List<SendResult> _results;  
  int callCount = 0;  
  
  @override  
  Future<SendResult> send({  
    required String sessionId,  
    required String deviceId,  
    required String payloadKind,  
    required List<String> records,  
    String? filePath,  
    required DateTime collectedAt,  
  }) async {  
    final SendResult r = _results[callCount];  
    callCount++;  
    return r;  
  }  
  
  @override  
  Future<SendResult> sendParts({  
    required String sessionId,  
    required String deviceId,  
    required String payloadKind,  
    required List<String> parts,  
    required DateTime collectedAt,  
  }) async =>  
      const SendResult(status: SendStatus.success, messageId: 1);  
  
  @override  
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);  
}  
  
void main() {  
  sqfliteFfiInit();  
  
  late Database db;  
  late TelegramQueue queue;  
  final DateTime now = DateTime.utc(2026, 1, 1);  
  
  setUp(() async {  
    db = await databaseFactoryFfi.openDatabase(  
      inMemoryDatabasePath,  
      options: OpenDatabaseOptions(  
        version: kSchemaVersion,  
        onCreate: (Database d, int v) => createSchema(d),  
      ),  
    );  
    queue = TelegramQueue(db);  
  });  
  
  tearDown(() async => db.close());  
  
  // =============================================================  
  // NHOM 1 - TC-IO-NOT-01 + TC-IO-13: gui that den chat dich  
  // CAN THIET BI THAT. Khong chay duoc tren desktop.  
  //  
  // Tien de: token + chat_id da cau hinh qua man hinh /settings.  
  // Cac buoc:  
  //   1. enqueue mot goi gia ('location', 3 ban ghi)  
  //   2. dung dispatcher THAT (sender that, client that)  
  //   3. runOnce()  
  //   4. khang dinh send_log co dong moi voi outcome 'success'  
  //  
  // GHI CHU: khong tu khang dinh tin den chat - do la buoc kiem THU CONG.  
  // Nguoi kiem thu phai mo Telegram va xac nhan tin da den.  
  // =============================================================  
  group('NHOM 1 - TC-IO-NOT-01 + TC-IO-13 (CAN THIET BI)', () {  
    test('gui that den chat dich, send_log co outcome success', () async {  
      fail(  
        'CAN THIET BI THAT: cau hinh token/chat_id qua /settings, '  
        'roi chay lai tren thiet bi. Khong chay duoc tren desktop.',  
      );  
    });  
  });  
  
  // =============================================================  
  // NHOM 2 - TC-IO-NOT-03: mat mang, hang doi bao toan  
  // CHAY DUOC TREN DESKTOP voi sender gia.  
  // =============================================================  
  group('NHOM 2 - TC-IO-NOT-03 (DESKTOP)', () {  
    test('goi VAN trong queue, attempts tang, nextAttemptAt o tuong lai',  
        () async {  
      await queue.enqueue(  
        sessionId: 'SES-NOT-03',  
        payloadKind: 'location',  
        payloadPath: '/tmp/offline',  
        recordCount: 3,  
      );  
      expect(await queue.countPending(), 1);  
  
      // Sender gia tra retryable - mo phong mat mang.  
      final FakeSender fs = FakeSender([  
        const SendResult(  
          status: SendStatus.retryable,  
          description: 'mo phong mat mang',  
        ),  
      ]);  
      final TelegramDispatcher d = TelegramDispatcher(  
        queue: queue,  
        sender: fs,  
        db: db,  
        readChatId: () => '5887530234',  
      );  
      await d.runOnce(now: now);  
  
      // Goi VAN trong queue - khong mat khi mat mang.  
      expect(await queue.countPending(), 1);  
    });  
  });  
  
  // =============================================================  
  // NHOM 3 - TC-IO-14: suspend/terminate  
  // CAN THIET BI THAT. Khong chay duoc tren desktop.  
  //  
  // Cac buoc:  
  //   1. enqueue goi, chay runOnce mot phan  
  //   2. dong app (vuot khoi da nhiem), mo lai  
  //   3. khang dinh queue con nguyen  
  // =============================================================  
  group('NHOM 3 - TC-IO-14 (CAN THIET BI)', () {  
    test('queue con nguyen sau khi dong/mo lai app', () async {  
      fail(  
        'CAN THIET BI THAT: dong app that (vuot khoi da nhiem) roi mo lai. '  
        'Khong mo phong duoc viec terminate tren desktop.',  
      );  
    });  
  });  
  
  // =============================================================  
  // NHOM 4 - TC-IO-NOT-05: gioi han tan suat  
  // CHAY DUOC TREN DESKTOP.  
  // =============================================================  
  group('NHOM 4 - TC-IO-NOT-05 (DESKTOP)', () {  
    test('nextAttemptAt xap xi now + 7 giay (KHONG phai backoff)',  
        () async {  
      await queue.enqueue(  
        sessionId: 'SES-NOT-05',  
        payloadKind: 'location',  
        payloadPath: '/tmp/rate',  
        recordCount: 1,  
      );  
      final FakeSender fs = FakeSender([  
        const SendResult(  
          status: SendStatus.retryable,  
          retryAfter: Duration(seconds: 7),  
          description: 'bi gioi han tan suat',  
        ),  
      ]);  
      final TelegramDispatcher d = TelegramDispatcher(  
        queue: queue,  
        sender: fs,  
        db: db,  
        readChatId: () => '5887530234',  
      );  
      await d.runOnce(now: now);  
  
      // retry_after quyet dinh, KHONG dung backoff (2 giay o lan thu 1).  
      final List<QueuedPacket> r = await queue.duePackets(  
        now: now.add(const Duration(seconds: 6)),  
        maxRetry: TelegramConfig.maxRetry,  
      );  
      expect(r, isEmpty); // chua du 7 giay  
      final List<QueuedPacket> r2 = await queue.duePackets(  
        now: now.add(const Duration(seconds: 8)),  
        maxRetry: TelegramConfig.maxRetry,  
      );  
      expect(r2.length, 1); // da qua 7 giay  
    });  
  });  
}  
