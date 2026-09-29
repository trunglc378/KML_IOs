import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Man hinh /onboarding - Gioi thieu va muc dich thu thap (bat buoc o lan chay dau).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              const Icon(
                Icons.security_outlined,
                size: 80,
                color: Color(0xFF007AFF),
              ),
              const SizedBox(height: 24),
              Text(
                'Hệ thống KML-iOS v4.0',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Ứng dụng thu thập dữ liệu và gửi kết quả qua Telegram Bot.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF8E8E93),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              _buildFeatureItem(
                context,
                icon: Icons.send_rounded,
                title: 'Kênh gửi Telegram Bot',
                description:
                    'Kết quả được gửi an toàn qua Bot API HTTPS tới nhóm đã whitelist.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                icon: Icons.lock_outline_rounded,
                title: 'Bảo mật tuyệt đối',
                description:
                    'Mọi bí mật được lưu trong Keychain thiết bị, không lưu vết trong log.',
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                context,
                icon: Icons.history_rounded,
                title: 'Nhật ký kiểm toán',
                description:
                    'Tra cứu chi tiết mọi phiên gửi dữ liệu ngay trên thiết bị.',
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/consent'),
                child: const Text('Bắt đầu'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF007AFF), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
