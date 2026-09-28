  
/// Dung noi dung tin nhan va chia phan.  
///  
/// THUAN HAM: khong goi mang, khong doc Keychain, khong cham SQLite,  
/// khong async. Nho vay test duoc toan bo ma khong can thiet bi.  
///  
/// Nguyen tac bat buoc:  
/// - Escape ky tu cho parse_mode = HTML truoc khi ghep (Muc 4)  
/// - Chia phan theo RANH GIOI BAN GHI, khong cat giua mot ban ghi (Muc 5)  
/// - Gioi han 4096 ky tu/tin lay tu TelegramConfig.maxMessageLength  
class TelegramMessageBuilder {  
  const TelegramMessageBuilder();
  
  
  /// Escape ky tu cho parse_mode = HTML cua Telegram.  
  ///  
  /// Phai escape dung BA ky tu: & < >  
  /// THU TU QUAN TRONG: & TRUOC, roi moi < va >.  
  /// Neu escape < truoc, ket qua &lt; sinh ra mot dau & moi, roi buoc escape &  
  /// se bien no thanh &amp;lt; - sai.  
  ///  
  /// KHONG escape dau ngoac kep hay nhay don: Telegram khong yeu cau, va escape  
  /// thua lam noi dung kho doc.  
  static String escapeHtml(String raw) {  
    // Thu tu bat buoc: & truoc.  
    return raw  
        .replaceAll('&', '&amp;')  
        .replaceAll('<', '&lt;')  
        .replaceAll('>', '&gt;');  
  }  
  
  /// Dung phan dau (ba dong dau + dai phan cach).  
  ///  
  /// Bon phan co dinh theo SDS v4.0 Muc 6.5:  
  ///   1. Dong dinh danh: platform, deviceId, ma phien  
  ///   2. Dong thoi gian: thu thap ISO 8601 UTC, gui ISO 8601 UTC  
  ///   3. Dong tong quan: loai du lieu, so ban ghi, chi so phan neu co  
  ///   4. Phan than (do nguoi goi noi tiep sau dai phan cach)  
  String buildHeader({  
    required String deviceId,  
    required String sessionId,  
    required DateTime collectedAt,  
    required DateTime sentAt,  
    required String payloadKind,  
    required int recordCount,  
    int? partIndex,  
    int? partTotal,  
  }) {  
    final StringBuffer b = StringBuffer();  
  
    // 1. Dong dinh danh. platform luon la ios theo quy tac 6.2 so 1.  
    b.writeln('KML-iOS · platform=ios · deviceId=' + escapeHtml(deviceId));  
    b.writeln('Phien: ' + escapeHtml(sessionId));  
  
    // 2. Dong thoi gian - ISO 8601 UTC.  
    b.writeln('Thu thap: ' + isoUtc(collectedAt) + ' · Gui: ' + isoUtc(sentAt));  
  
    // 3. Dong tong quan - chi so phan CHI ghi khi biet ca partIndex va partTotal.  
    String overview = 'Loai: ' + escapeHtml(payloadKind) +  
        ' · So ban ghi: ' + recordCount.toString();  
    if (partIndex != null && partTotal != null && partTotal > 1) {  
      overview = overview + ' · [Phan ' + partIndex.toString() + '/' +  
          partTotal.toString() + ']';  
    }  
    b.writeln(overview);  
  
    // 4. Dai phan cach - phan than bat dau sau dong nay.  
    b.writeln(separator);  
    return b.toString();  
  }  
  
  /// Chia danh sach ban ghi thanh cac phan vua maxLength ky tu.  
  ///  
  /// KHONG cat giua mot ban ghi. Moi phan tra ve la mot chuoi da ghep  
  /// phan dau + than cua phan do.  
  ///  
  /// THUAT TOAN HAI LUOT (ly do: chi so phan phai ghi SAU khi biet tong so phan):  
  ///   Luot 1: chia than thanh cac nhom ban ghi, moi nhom vua maxLength.  
  ///   Luot 2: biet tong so phan, roi moi ghep phan dau co chi so dung.  
  /// Neu ghep [Phan 1/1] truoc roi moi phat hien co ba phan, chi so se sai toan bo.  
  ///  
  /// [headerBuilder] nhan (partIndex, partTotal) de dung phan dau co chi so dung.  
  /// [onOversizeRecord] duoc goi khi mot ban ghi don le dai hon maxLength -  
  ///   ban ghi do duoc dat rieng mot phan, KHONG bi cat.  
  List<String> splitIntoParts({  
    required List<String> records,  
    required String Function(int partIndex, int partTotal) headerBuilder,  
    required int maxLength,
    void Function(int index, int length)? onOversizeRecord,  
  }) {  
  
    // Danh sach rong -> mot phan chi co phan dau, khong crash.  
    if (records.isEmpty) {  
      return <String>[headerBuilder(1, 1)];  
    }  
  
    // Uoc luong do dai phan dau de tru vao han muc than cua moi phan.  
    final int headerReserve = headerBuilder(1, 1).length;  
    final int bodyLimit = maxLength - headerReserve;  
  
    // LUOT 1: chia than thanh cac nhom ban ghi, KHONG cat giua ban ghi.  
    final List<List<String>> groups = <List<String>>[];  
    List<String> current = <String>[];  
    int currentLen = 0;  
  
    for (int i = 0; i < records.length; i++) {  
      final String rec = records[i];  
      final int recLen = rec.length + 1;  
  
      // Ban ghi don le dai hon han muc than: dat rieng, KHONG cat.  
      if (recLen > bodyLimit) {  
        if (current.isNotEmpty) {  
          groups.add(current);  
          current = <String>[];  
          currentLen = 0;  
        }  
        groups.add(<String>[rec]);  
        onOversizeRecord?.call(i, recLen);  
        continue;  
      }  
  
      if (current.isEmpty) {  
        current.add(rec);  
        currentLen = recLen;  
        continue;  
      }  
      if (currentLen + recLen > bodyLimit) {  
        // Chot phan hien tai o RANH GIOI BAN GHI - ban ghi moi sang phan sau.  
        groups.add(current);  
        current = <String>[rec];  
        currentLen = recLen;  
      } else {  
        current.add(rec);  
        currentLen = currentLen + recLen;  
      }  
    }  
    if (current.isNotEmpty) groups.add(current);  
  
    // LUOT 2: da biet tong so phan, ghep phan dau co chi so dung.  
    final int total = groups.length;  
    final List<String> parts = <String>[];  
    for (int i = 0; i < total; i++) {  
      final String h = headerBuilder(i + 1, total);  
      parts.add(h + groups[i].join('\n'));  
    }  
    return parts;  
  }  
  
  /// Dai phan cach giua phan dau va phan than (SDS v4.0 Muc 6.5).  
  static const String separator = '--------------';  
  
  /// Dinh dang thoi gian ISO 8601 UTC, thong nhat voi DTO (Muc 9.4).  
  /// Vi du: 2026-09-25T08:00:00Z  
  static String isoUtc(DateTime dt) {  
    final String s = dt.toUtc().toIso8601String();  
    final int dot = s.indexOf('.');  
    final String base = dot >= 0 ? s.substring(0, dot) : s;  
    return base.endsWith('Z') ? base : base + 'Z';  
  }  
}  
