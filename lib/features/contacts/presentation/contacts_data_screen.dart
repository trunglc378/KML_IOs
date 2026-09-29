import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/contacts_collector_repository_impl.dart';
import '../domain/entities/contact_entry_entity.dart';
import '../domain/repositories/contacts_collector_repository.dart';

final contactsCollectorProvider = Provider<ContactsCollectorRepository>((Ref ref) {
  return ContactsCollectorRepositoryImpl();
});

final contactsFutureProvider = FutureProvider<List<ContactEntryEntity>>((Ref ref) async {
  final ContactsCollectorRepository repo = ref.watch(contactsCollectorProvider);
  return repo.fetchContacts();
});

/// Man hinh thu thap va hien thi danh ba (/data/contacts).
class ContactsDataScreen extends ConsumerWidget {
  const ContactsDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ContactEntryEntity>> contacts = ref.watch(contactsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh bạ (Contacts)'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại danh bạ',
            onPressed: () => ref.refresh(contactsFutureProvider),
          ),
        ],
      ),
      body: contacts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object err, StackTrace st) => Center(
          child: Text('Lỗi truy cập danh bạ: $err', style: const TextStyle(color: Colors.red)),
        ),
        data: (List<ContactEntryEntity> items) {
          if (items.isEmpty) {
            return const Center(child: Text('Không có liên hệ nào hoặc chưa cấp quyền.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (BuildContext context, int index) => const Divider(),
            itemBuilder: (BuildContext context, int index) {
              final ContactEntryEntity c = items[index];
              return ListTile(
                leading: CircleAvatar(child: Text(c.displayName.isNotEmpty ? c.displayName[0] : '?')),
                title: Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    if (c.phones.isNotEmpty) Text('SĐT: ${c.phones.join(', ')}'),
                    if (c.emails.isNotEmpty) Text('Email: ${c.emails.join(', ')}'),
                    const SizedBox(height: 4),
                    Text(
                      c.toRecordLine(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.blueGrey),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
