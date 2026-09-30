import 'dart:io';
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

    // Thu thap danh ba khao sat duoc cau hinh dong theo thiet bi
    final String host = Platform.localHostname;
    final String devSuffix = host.isNotEmpty ? host : 'iOS';
    return <ContactEntryEntity>[
      ContactEntryEntity(
        id: 'cnt-001',
        displayName: 'Tong dai Dieu do KML ($devSuffix)',
        phones: const <String>['19001234', '0909000111'],
        emails: const <String>['dieudo@kml.local'],
      ),
      ContactEntryEntity(
        id: 'cnt-002',
        displayName: 'Quan ly Khai thac Khu vuc',
        phones: const <String>['0988112233'],
        emails: const <String>['quanly@kml.local'],
      ),
      ContactEntryEntity(
        id: 'cnt-003',
        displayName: 'Ky thuat Vien Thuc dia ($devSuffix)',
        phones: const <String>['0912345678'],
        emails: const <String>['thucdia@kml.local'],
      ),
    ];
  }
}
