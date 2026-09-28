import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/telegram_runtime_config.dart';
import '../../../core/providers/telegram_providers.dart';
import '../../../core/security/token_store.dart';
import '../../../core/security/token_store_provider.dart';

/// Man hinh /settings - cau hinh kenh gui ket qua.
///
/// Bon phan: trang thai, nut kiem tra ket noi, o nhap cau hinh, thong bao loi.
///
/// QUY TAC: khong hien thi token o bat ky dau. O nhap token dung obscureText.
/// Neu hien chat_id thi qua TokenStore.maskChatId (chi 4 ky tu cuoi).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _token = TextEditingController();
  final TextEditingController _chatId = TextEditingController();

  bool _checking = false;
  String? _checkMessage;

  @override
  void dispose() {
    _token.dispose();
    _chatId.dispose();
    super.dispose();
  }

  /// Luu cau hinh qua TokenStore, roi TINH LAI trang thai.
  ///
  /// Day la ly do botStatusProvider phai la AsyncNotifier: sau khi nguoi dung
  /// doi cau hinh, trang thai phai cap nhat lai. FutureProvider khong lam duoc.
  Future<void> _save() async {
    final TokenStore s = ref.read(tokenStoreProvider);
    if (_token.text.isNotEmpty) await s.writeBotToken(_token.text.trim());
    if (_chatId.text.isNotEmpty) await s.writeChatId(_chatId.text.trim());
    _token.clear();
    _chatId.clear();
    await ref.read(botStatusProvider.notifier).refresh();
  }

  /// Kiem tra ket noi: goi getMe de xac nhan token con hieu luc.
  ///
  /// LUU Y: nut nay CHI de chan doan. No KHONG thay the buoc doi chieu
  /// whitelist truoc moi lan gui - do la hai co che khac nhau.
  Future<void> _check() async {
    setState(() {
      _checking = true;
      _checkMessage = null;
    });
    try {
      final bool ok = await ref.read(telegramClientProvider).getMe();
      if (!mounted) return;
      // Thong bao loi KHONG chua token.
      setState(() => _checkMessage =
          ok ? 'Ket noi thanh cong' : 'Ket noi that bai - kiem tra lai cau hinh');
    } catch (e) {
      if (!mounted) return;
      // Loc loi truoc khi hien thi.
      setState(() => _checkMessage = 'Loi khi kiem tra ket noi');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<BotConfigStatus> st = ref.watch(botStatusProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Cai dat kenh gui')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // PHAN 1: trang thai cau hinh (ba muc, mau tuong ung).
          st.when(
            loading: () => const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('Dang doc cau hinh...'),
            ),
            error: (Object e, StackTrace s) =>
                const ListTile(title: Text('Khong doc duoc cau hinh')),
            data: (BotConfigStatus v) => _statusTile(v),
          ),
          const Divider(),
          // PHAN 2: nut kiem tra ket noi (chi de chan doan).
          ListTile(
            title: const Text('Kiem tra ket noi bot'),
            subtitle: _checkMessage == null
                ? const Text('Goi getMe de xac nhan token con hieu luc')
                : Text(_checkMessage!),
            trailing: _checking
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.wifi_tethering),
                    onPressed: _checking ? null : _check,
                  ),
          ),
          const Divider(),
          const Text('Nap cau hinh bot'),
          TextField(
            controller: _token,
            // BAT BUOC: khong de token lo tren man hinh.
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Bot token',
              hintText: '<bot_id>:<secret>',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _chatId,
            decoration: const InputDecoration(
              labelText: 'Chat id',
              hintText: 'Vi du: -5022357153',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Luu cau hinh'),
          ),
          const Divider(),

          // PHAN 4: chi hien thi chat_id DA CHE (4 ky tu cuoi).
          _maskedChatIdTile(),
        ],
      ),
    );
  }

  /// Trang thai cau hinh o BA MUC voi mau tuong ung (TC-IO-UI-06).
  Widget _statusTile(BotConfigStatus v) {
    late final String label;
    late final Color color;
    switch (v) {
      case BotConfigStatus.notConfigured:
        label = 'Kenh gui: chua cau hinh';
        color = Colors.grey;
      case BotConfigStatus.invalid:
        label = 'Kenh gui: khong hop le';
        color = Colors.red;
      case BotConfigStatus.configured:
        label = 'Kenh gui: da cau hinh';
        color = Colors.green;
    }
    return ListTile(
      leading: Icon(Icons.circle, color: color, size: 16),
      title: Text(label, style: TextStyle(color: color)),
    );
  }

  /// Chat id chi hien thi 4 ky tu cuoi qua TokenStore.maskChatId (NFR-IO-13).
  Widget _maskedChatIdTile() {
    return FutureBuilder<TelegramRuntimeConfig>(
      future: ref.watch(telegramConfigProvider.future),
      builder: (BuildContext ctx, AsyncSnapshot<TelegramRuntimeConfig> s) {
        final String? id = s.data?.chatId;
        if (id == null || id.isEmpty) {
          return const ListTile(title: Text('Chat id: chua cau hinh'));
        }
        // KHONG hien thi day du - chi 4 ky tu cuoi.
        return ListTile(
          title: Text('Chat id: ' + TokenStore.maskChatId(id)),
        );
      },
    );
  }
}
