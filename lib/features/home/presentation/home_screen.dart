import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/telegram_runtime_config.dart';
import '../../../core/providers/telegram_providers.dart';

/// Trang chinh /home - Tong quan he thong va dieu huong den cac chuc nang (SDS v4.0 Muc 3.3).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<BotConfigStatus> botStatus = ref.watch(botStatusProvider);
    final AsyncValue<int> pendingPackets = ref.watch(sendQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KML-iOS v4.0'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildStatusBanner(context, botStatus, pendingPackets),
          const SizedBox(height: 20),
          const Text(
            'Hệ thống & Kiểm toán',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildActionTile(
            context,
            icon: Icons.history_rounded,
            title: 'Nhật ký gửi kết quả (Audit Log)',
            subtitle: 'Tra cứu lịch sử gửi tin nhắn và tệp',
            onTap: () => context.push('/audit-log'),
          ),
          _buildActionTile(
            context,
            icon: Icons.sync_rounded,
            title: 'Hàng đợi gửi (Telegram Queue)',
            subtitle: 'Xem các gói đang chờ gửi theo backoff',
            onTap: () => context.push('/sync'),
          ),
          _buildActionTile(
            context,
            icon: Icons.verified_user_outlined,
            title: 'Đồng ý & Quyền riêng tư (Consent)',
            subtitle: 'Thông báo minh bạch kênh gửi Telegram',
            onTap: () => context.push('/consent'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Mô-đun thu thập dữ liệu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildDataGrid(context),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(
    BuildContext context,
    AsyncValue<BotConfigStatus> botStatus,
    AsyncValue<int> pendingPackets,
  ) {
    final Color bannerColor;
    final String statusText;
    final IconData statusIcon;

    final BotConfigStatus status =
        botStatus.value ?? BotConfigStatus.notConfigured;
    switch (status) {
      case BotConfigStatus.configured:
        bannerColor = Colors.green;
        statusText = 'Bot đã cấu hình · Kênh sẵn sàng';
        statusIcon = Icons.check_circle_rounded;
      case BotConfigStatus.notConfigured:
        bannerColor = Colors.orange;
        statusText = 'Bot chưa cấu hình · Cần nạp thông tin';
        statusIcon = Icons.warning_rounded;
      case BotConfigStatus.invalid:
        bannerColor = Colors.red;
        statusText = 'Bot không hợp lệ · Kiểm tra token/chat_id';
        statusIcon = Icons.error_rounded;
    }

    final int pending = pendingPackets.value ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(statusIcon, color: bannerColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: bannerColor,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text('Gói đang chờ gửi trong queue:'),
              Text(
                pending.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF007AFF)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildDataGrid(BuildContext context) {
    final List<(String, String, IconData)> items = <(String, String, IconData)>[
      ('/data/device', 'Thiết bị & Mạng', Icons.phone_iphone_rounded),
      ('/data/location', 'Định vị GPS', Icons.location_on_rounded),
      ('/data/contacts', 'Danh bạ', Icons.contacts_rounded),
      ('/data/calendar', 'Lịch', Icons.calendar_today_rounded),
      ('/data/photos', 'Thư viện ảnh', Icons.photo_library_rounded),
      ('/data/camera', 'Camera', Icons.camera_alt_rounded),
      ('/data/microphone', 'Ghi âm', Icons.mic_rounded),
      ('/data/screen', 'Ghi màn hình', Icons.screen_share_rounded),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemCount: items.length,
      itemBuilder: (BuildContext ctx, int i) {
        final (String path, String label, IconData icon) = items[i];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push(path),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: <Widget>[
                  Icon(icon, color: const Color(0xFF007AFF), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
