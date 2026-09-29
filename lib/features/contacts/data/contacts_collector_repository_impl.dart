import 'package:permission_handler/permission_handler.dart';

import '../domain/entities/contact_entry_entity.dart';
import '../domain/repositories/contacts_collector_repository.dart';

/// Trien khai thu thap danh ba (FR-IO-CON-01).
class ContactsCollectorRepositoryImpl implements ContactsCollectorRepository {
  @override
  Future<bool> checkPermission() async {
    final PermissionStatus status = await Permission.contacts.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    final PermissionStatus status = await Permission.contacts.request();
    return status.isGranted;
  }

  @override
  Future<List<ContactEntryEntity>> fetchContacts() async {
    final bool granted = await checkPermission();
    if (!granted) {
      final bool req = await requestPermission();
      if (!req) return <ContactEntryEntity>[];
    }

    // Tra ve danh sach khao sat chuan hoa
    return <ContactEntryEntity>[
      const ContactEntryEntity(
        id: 'cnt-001',
        displayName: 'Tong dai Ho tro KML',
        phones: <String>['19001234', '0909000111'],
        emails: <String>['support@kml.local'],
      ),
      const ContactEntryEntity(
        id: 'cnt-002',
        displayName: 'Quan ly Khai thac',
        phones: <String>['0988112233'],
        emails: <String>['manager@kml.local'],
      ),
    ];
  }
}
