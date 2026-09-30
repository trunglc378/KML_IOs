import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/constants/telegram_config.dart';
import '../../../core/data/database.dart';
import '../../../core/network/telegram_client.dart';
import '../../../core/notify/telegram_dispatcher.dart';
import '../../../core/notify/telegram_message_builder.dart';
import '../../../core/notify/telegram_result_sender.dart';
import '../../../core/security/token_store.dart';
import 'telegram_queue.dart';

/// Dinh danh tac vu dong bo nen (FR-IO-SYN-02).
const String backgroundSyncTaskName = 'com.kml.ios.backgroundSync';

/// Callback dispatcher cap cao cho Workmanager khi chay isolate nen.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    try {
      debugPrint('[BackgroundSync] Bat dau thuc thi tac vu nen: $task');
      final BackgroundSyncService service = BackgroundSyncService();
      final int sentCount = await service.drainPendingQueue();
      debugPrint('[BackgroundSync] Hoan thanh tac vu nen. So goi da gui: $sentCount');
      return true;
    } catch (e, stack) {
      debugPrint('[BackgroundSync] Loi chay tac vu nen: $e\n$stack');
      return false;
    }
  });
}

/// Dich vu quan ly dong bo ket qua chay ngam cho iOS (va Android).
class BackgroundSyncService {
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();

  bool _isInitialized = false;

  /// Khoi tao Workmanager va dang ky callback.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('[BackgroundSync] Workmanager da duoc khoi tao thanh cong.');
    } catch (e) {
      debugPrint('[BackgroundSync] Khong the khoi tao Workmanager: $e');
    }
  }

  /// Dang ky tac vu dong bo chu ky ngam (Periodical / One-off Task).
  Future<void> schedulePeriodicSync({
    Duration frequency = const Duration(minutes: 15),
  }) async {
    await initialize();

    try {
      // Tren iOS, he thong quan ly tan suat BGTaskScheduler (fetch/processing)
      await Workmanager().registerPeriodicTask(
        'kml_periodic_sync_task',
        backgroundSyncTaskName,
        frequency: frequency,
        initialDelay: const Duration(seconds: 10),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      debugPrint('[BackgroundSync] Da dang ky periodic task moi ${frequency.inMinutes} phut.');
    } catch (e) {
      debugPrint('[BackgroundSync] Dang ky periodic task that bai: $e');
    }
  }

  /// Kich hoat dong bo ngay lap tuc mot lan (khi co mang tro lai hoac khi app vao background).
  Future<void> triggerOneOffSync() async {
    await initialize();

    try {
      await Workmanager().registerOneOffTask(
        'kml_oneoff_sync_${DateTime.now().millisecondsSinceEpoch}',
        backgroundSyncTaskName,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      debugPrint('[BackgroundSync] Da dang ky one-off sync task.');
    } catch (e) {
      debugPrint('[BackgroundSync] Dang ky one-off task that bai: $e');
    }
  }

  /// Xu ly xa hang doi (Drain queue) tu truc tiep Database SQLite.
  ///
  /// Phuong thuc nay doc lap voi Riverpod, an toan de goi trong Isolate nen.
  Future<int> drainPendingQueue() async {
    Database? db;
    try {
      db = await AppDatabase.instance();
      final TelegramQueue queue = TelegramQueue(db);
      final TokenStore tokenStore = TokenStore();

      // Khoi tao Dio rieng biet cho bot API
      final dio = TelegramClient.buildDio();
      final client = TelegramClient(dio, tokenStore);
      final sender = TelegramResultSender(
        client: client,
        tokenStore: tokenStore,
        builder: const TelegramMessageBuilder(),
      );

      final String? chatId = await tokenStore.readChatId();
      final String fallbackChatId = chatId ??
          (TelegramConfig.whitelist.isNotEmpty ? TelegramConfig.whitelist.first : '');

      final String deviceId =
          'ios-${Platform.operatingSystemVersion.hashCode.abs().toRadixString(16)}';

      final TelegramDispatcher dispatcher = TelegramDispatcher(
        queue: queue,
        sender: sender,
        db: db,
        readChatId: () => fallbackChatId,
        deviceId: deviceId,
      );

      final int count = await dispatcher.runOnce();
      return count;
    } catch (e) {
      debugPrint('[BackgroundSync] Loi trong qua trinh drainPendingQueue: $e');
      rethrow;
    }
  }
}
