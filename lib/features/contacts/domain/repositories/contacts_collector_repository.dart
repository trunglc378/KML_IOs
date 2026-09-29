import 'entities/contact_entry_entity.dart';

/// Giao dien thu thap danh ba thiet bi.
abstract class ContactsCollectorRepository {
  Future<bool> checkPermission();
  Future<bool> requestPermission();
  Future<List<ContactEntryEntity>> fetchContacts();
}
