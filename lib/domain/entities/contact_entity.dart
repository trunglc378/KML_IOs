/// Thuc the danh ba (Contact) o tang Domain (SDS v4.0 Muc 8.2).
///
/// Thuan khiet, khong import package ha tang.
class ContactEntity {
  const ContactEntity({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.collectedAt,
    this.sent = false,
  });

  final int? id;
  final String name;
  final String phone;
  final String? email;
  final String collectedAt;
  final bool sent;
}
