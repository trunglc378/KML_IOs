import 'package:flutter/material.dart';

/// Man hinh /consent - noi dung kenh gui ket qua (FR-IO-NOT-05).
///
/// RANG BUOC THU TU: man hinh nay phai xuat hien TRUOC hop thoai xin quyen he
/// thong. Vi vay lop nay KHONG tu goi quyen trong initState. No chi goi
/// [onConsentAccepted] khi nguoi dung nhan nut tiep tuc; nguoi goi (router)
/// chiu trach nhiem xin quyen SAU do.
///
/// Noi dung phai khop voi khai bao privacy manifest (SDS Muc 10.3).
class ConsentScreen extends StatelessWidget {
  const ConsentScreen({super.key, required this.onConsentAccepted});

  /// Duoc goi SAU khi nguoi dung da doc va dong y. Day la diem duy nhat
  /// trong man hinh nay kich hoat buoc tiep theo (xin quyen he thong).
  final VoidCallback onConsentAccepted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thong bao truoc khi cap quyen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('Du lieu duoc thu thap nhu the nao', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text(
            '1. Du lieu thuoc pham vi public API va permission cua iOS. Ung dung'
            ' khong truy cap bat ky thu gi ngoai pham vi nay.',
          ),
          const SizedBox(height: 16),
          const Text(
            '2. Ket qua thu thap duoc GUI TOI MOT CHAT TELEGRAM da cau hinh.'
            ' Du lieu khong chi nam lai tren thiet bi.',
          ),
          const SizedBox(height: 16),
          const Text(
            '3. Dich vu nhan la ben thu ba - Telegram - khong thuoc ha tang cua'
            ' he thong. Sau khi gui, he thong KHONG THE xoa hoac thu hoi ket qua.'
            ' Du lieu nam tren ha tang cua ben ngoai.',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            // Chi khi nguoi dung nhan nut nay thi buoc xin quyen moi duoc chay.
            onPressed: onConsentAccepted,
            child: const Text('Toi da hieu, tiep tuc'),
          ),
        ],
      ),
    );
  }
}
