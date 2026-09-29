import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/telegram_providers.dart';

/// Man hinh /audit-log - doc send_log.
///
/// Day la NGUON TRA CUU DUY NHAT sau khi doi kenh sang Telegram, vi khong con
/// Dashboard. Phai tra loi duoc: goi nao da gui, luc nao, may lan, ket qua ra sao.
class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<SendLogRow>> rows = ref.watch(auditLogProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Nhat ky gui ket qua')),
      body: rows.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) =>
            const Center(child: Text('Khong doc duoc nhat ky')),
        data: (List<SendLogRow> data) => _buildTable(context, data),
      ),
    );
  }

  /// Sau cot: sentAt, sessionId, method, chatIdSuffix, attempts, outcome.
  /// chatIdSuffix hien thi NGUYEN VAN - no da chi co 4 ky tu cuoi, khong can che.
  Widget _buildTable(BuildContext context, List<SendLogRow> rows) {
    if (rows.isEmpty) {
      return const Center(child: Text('Chua co ban ghi gui nao'));
    }
    final int ok = rows.where((SendLogRow r) => r.outcome == 'success').length;
    final int fail = rows.length - ok;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Tong: ${rows.length}  ·  Thanh cong: $ok  ·  That bai: $fail',
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const <DataColumn>[
                  DataColumn(label: Text('sentAt')),
                  DataColumn(label: Text('sessionId')),
                  DataColumn(label: Text('method')),
                  DataColumn(label: Text('chatIdSuffix')),
                  DataColumn(label: Text('attempts')),
                  DataColumn(label: Text('outcome')),
                ],
                rows: rows.map((SendLogRow r) => DataRow(
                      cells: <DataCell>[
                        DataCell(Text(r.sentAt)),
                        DataCell(Text(r.sessionId)),
                        DataCell(Text(r.method)),
                        DataCell(Text(r.chatIdSuffix)),
                        DataCell(Text(r.attempts.toString())),
                        DataCell(Text(r.outcome)),
                      ],
                    )).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
