/// Thuc the lien he trong danh ba (FR-IO-CON-01).
///
/// Tang Domain thuan khiet, khong phu thuoc platform hay SDK ngoai.
class ContactEntryEntity {
  const ContactEntryEntity({
    required this.id,
    required this.displayName,
    required this.phones,
    required this.emails,
  });

  final String id;
  final String displayName;
  final List<String> phones;
  final List<String> emails;

  /// Dinh dang DTO mot dong (SDS Muc 6.5):
  /// id=123 name="Nguyen Van A" phones=["0901234567"] emails=["a@example.com"]
  String toRecordLine() {
    final String pStr = phones.map((String p) => '"$p"').join(',');
    final String eStr = emails.map((String e) => '"$e"').join(',');
    return 'id=$id name="$displayName" phones=[$pStr] emails=[$eStr]';
  }
}
