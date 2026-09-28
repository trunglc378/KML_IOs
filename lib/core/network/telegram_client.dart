import 'dart:io';  
  
import 'package:dio/dio.dart';  
  
import '../constants/telegram_config.dart';  
import '../notify/send_result.dart';  
import '../security/token_store.dart';  
  
/// Client goi Telegram Bot API.  
///  
/// Instance dio RIENG, khong dung chung: token nam trong duong dan URL.  
/// validateStatus luon true: Bot API tra HTTP 200 kem ok:false.  
/// Khong log URL tuyet doi o bat ky nhanh nao.  
///  
/// RANG BUOC: lop nay KHONG tu quyet dinh gui van ban hay gui tep.  
/// Viec chon phuong thuc thuoc TelegramResultSender (buoc 7).  
class TelegramClient {  
  TelegramClient(this.dio, this.tokenStore);  
  
  final Dio dio;  
  final TokenStore tokenStore;  
  
  /// Dung dio instance RIENG cho Bot API.  
  static Dio buildDio() {  
    final Dio dio = Dio(BaseOptions(  
      baseUrl: TelegramConfig.apiBase,  
      connectTimeout: TelegramConfig.connectTimeout,  
      receiveTimeout: TelegramConfig.receiveTimeout,  
      sendTimeout: TelegramConfig.sendTimeout,  
      validateStatus: (int? _) => true,  
    ));  
    dio.interceptors.add(InterceptorsWrapper(  
      onRequest: (RequestOptions o, RequestInterceptorHandler h) {  
        o.extra['safeUrl'] = safeUrl(o.uri.toString());  
        h.next(o);  
      },  
    ));  
    return dio;  
  }  
  
  /// Che token trong URL Bot API: /bot123:***/sendMessage  
  static String safeUrl(String url) {  
    String out = url.replaceFirst(TelegramConfig.apiBase, '');  
    out = out.replaceAllMapped(  
      RegExp(r'/bot([0-9]{4,}):[A-Za-z0-9_-]+'),  
      (Match m) => '/bot${m.group(1)!}:***',  
    );  
    return out;  
  }  
  
  /// Duong dan endpoint, co tien to token. KHONG BAO GIO log gia tri nay.  
  String endpoint(String method, String token) => '/bot$token/$method';  
  
  /// Goi sendMessage. Text da duoc escape boi TelegramMessageBuilder (buoc 6).  
  Future<SendResult> sendMessage({  
    required String chatId,  
    required String text,  
    String parseMode = 'HTML',  
  }) async {  
    final String? token = await tokenStore.readBotToken();  
    if (token == null || token.isEmpty) {  
      return SendResult(  
        status: SendStatus.fatalAuth,  
        description: 'Bot token chua duoc cau hinh',  
      );  
    }  
    return _execute(  
      method: 'sendMessage',  
      token: token,  
      data: <String, dynamic>{  
        'chat_id': chatId,  
        'text': text,  
        'parse_mode': parseMode,  
      },  
    );  
  }  
  
  /// Goi sendDocument. FormData voi file tu filePath.  
  Future<SendResult> sendDocument({  
    required String chatId,  
    required String filePath,  
    String? caption,  
  }) async {  
    final String? token = await tokenStore.readBotToken();  
    if (token == null || token.isEmpty) {  
      return SendResult(  
        status: SendStatus.fatalAuth,  
        description: 'Bot token chua duoc cau hinh',  
      );  
    }  
    final FormData form = FormData.fromMap(<String, dynamic>{  
      'chat_id': chatId,  
      if (caption != null && caption.isNotEmpty) 'caption': caption,  
      'document': await MultipartFile.fromFile(filePath),  
    });  
    return _execute(method: 'sendDocument', token: token, data: form);  
  }  
  
  /// Goi sendPhoto.  
  Future<SendResult> sendPhoto({  
    required String chatId,  
    required String filePath,  
    String? caption,  
  }) async {  
    final String? token = await tokenStore.readBotToken();  
    if (token == null || token.isEmpty) {  
      return SendResult(  
        status: SendStatus.fatalAuth,  
        description: 'Bot token chua duoc cau hinh',  
      );  
    }  
    final FormData form = FormData.fromMap(<String, dynamic>{  
      'chat_id': chatId,  
      if (caption != null && caption.isNotEmpty) 'caption': caption,  
      'photo': await MultipartFile.fromFile(filePath),  
    });  
    return _execute(method: 'sendPhoto', token: token, data: form);  
  }  
  
  /// Kiem tra token con hieu luc. Dung cho nut kiem tra ket noi o /settings.  
  Future<bool> getMe() async {  
    final String? token = await tokenStore.readBotToken();  
    if (token == null || token.isEmpty) return false;  
    final SendResult r = await _execute(  
      method: 'getMe',  
      token: token,  
      isGet: true,  
    );  
    return r.status == SendStatus.success;  
  }  
  
  /// Goi Bot API va chuan hoa ket qua ve SendResult.  
  Future<SendResult> _execute({  
    required String method,  
    required String token,  
    Object? data,  
    bool isGet = false,  
  }) async {  
    try {  
      final Response<dynamic> res = await dio.request<dynamic>(  
        endpoint(method, token),  
        data: data,  
        options: Options(method: isGet ? 'GET' : 'POST'),  
      );  
      return _normalize(res, method);  
    } on DioException catch (e) {  
      // Loi mang / timeout -> retryable (backoff mac dinh).  
      if (e.type == DioExceptionType.connectionTimeout ||  
          e.type == DioExceptionType.sendTimeout ||  
          e.type == DioExceptionType.receiveTimeout) {  
        return SendResult(  
          status: SendStatus.retryable,  
          description: 'Het thoi gian cho khi goi Bot API',  
        );  
      }  
      final Response<dynamic>? r = e.response;  
      if (r != null) return _normalize(r, method);  
      return SendResult(  
        status: SendStatus.retryable,  
        description: e.error is SocketException  
            ? 'Loi socket khi goi Bot API'  
            : 'Loi mang khi goi Bot API',  
      );  
    }  
  }  
  
  /// Chuan hoa phan hoi theo bang anh xa loi (buoc 5, Muc 4).  
  SendResult _normalize(Response<dynamic> res, String method) {  
    final int http = res.statusCode ?? 0;  
    final dynamic body = res.data;  
  
    // HTTP 429 - gioi han tan suat. retry_after LUON uu tien hon backoff.  
    if (http == 429) {  
      Duration? ra;  
      if (body is Map && body['parameters'] is Map) {  
        final dynamic v = (body['parameters'] as Map)['retry_after'];  
        if (v is int && v > 0) ra = Duration(seconds: v);  
      }  
      return SendResult(  
        status: SendStatus.retryable,  
        method: method,
        serverErrorCode: 429,  
        retryAfter: ra ?? const Duration(seconds: 30),  
        description: 'Bi gioi han tan suat',  
      );  
    }  
  
    // HTTP 5xx - loi phia Telegram -> retryable (backoff luy tien).  
    if (http >= 500) {  
      return SendResult(  
        status: SendStatus.retryable,  
        method: method,
        serverErrorCode: http,  
        description: 'May chu Telegram tra HTTP $http',  
      );  
    }  
  
    // HTTP 401 - token sai hoac bi thu hoi -> fatalAuth, KHONG thu lai.  
    if (http == 401) {  
      return SendResult(  
        status: SendStatus.fatalAuth,  
        method: method,
        serverErrorCode: 401,  
        description: 'Bot token khong hop le hoac da bi thu hoi',  
      );  
    }  
  
    // HTTP 400 - tham so sai -> fatalConfig, KHONG thu lai.  
    if (http == 400) {  
      return SendResult(  
        status: SendStatus.fatalConfig,  
        method: method,
        serverErrorCode: 400,  
        description: 'Yeu cau khong hop le',  
      );  
    }  
  
    // HTTP 403 - bot khong co quyen gui toi chat -> fatalConfig.  
    if (http == 403) {  
      return SendResult(  
        status: SendStatus.fatalConfig,  
        method: method,
        serverErrorCode: 403,  
        description: 'Bot khong co quyen gui toi chat nay',  
      );  
    }  
  
    // HTTP 413 hoac mo ta neu file qua lon -> oversize (bo goi).  
    if (http == 413) {  
      return SendResult(  
        status: SendStatus.oversize,  
        method: method,
        serverErrorCode: 413,  
        description: 'Tep vuot gioi han Bot API',  
      );  
    }  
  
    // Kiem tra truong ok TRUOC khi coi la thanh cong. Day la dieu kien quyet dinh.  
    if (body is Map) {  
      final Map<dynamic, dynamic> j = body;  
      if (j['ok'] == true) {  
        int? mid;  
        final dynamic r = j['result'];  
        if (r is Map && r['message_id'] is int) mid = r['message_id'] as int;  
        return SendResult(
          status: SendStatus.success,
          messageId: mid,
          method: method,
        );
      }  
  
      // ok:false - doc mo ta de phan biet chat not found / file qua lon.  
      final String desc = j['description'] is String ? j['description'] as String : '';  
      final String low = desc.toLowerCase();  
      final int? ec = j['error_code'] is int ? j['error_code'] as int : null;  
  
      if (low.contains('chat not found')) {  
        return SendResult(  
          status: SendStatus.fatalConfig,  
          method: method,
          serverErrorCode: ec,  
          description: 'Khong tim thay chat - mo bot va nhan start',  
        );  
      }  
      if (low.contains('too large') || low.contains('file is too big')) {  
        return SendResult(  
          status: SendStatus.oversize,  
          method: method,
          serverErrorCode: ec,  
          description: 'Tep vuot gioi han Bot API',  
        );  
      }  
      // Cac ok:false con lai: loi cau hinh, khong thu lai.  
      return SendResult(  
        status: SendStatus.fatalConfig,  
        method: method,
        serverErrorCode: ec,  
        description: 'Bot API tra ok:false',  
      );  
    }  
  
    // Phan hoi khong phai JSON - coi la loi thu lai duoc (co gioi han.)  
    return SendResult(  
      status: SendStatus.retryable,  
      method: method,
      description: 'Phan hoi khong dung dinh dang JSON',  
    );  
  }  
}  
