import '../entities/contact_entity.dart';
import '../repositories/data_collection_repository.dart';

/// UseCase lay danh ba thiet bi (FR-IO-CON-01).
///
/// Tang Domain thuan khiet, tuan thu quy tac quyen hop le tai thoi diem thu thap.
class GetContactsUseCase {
  const GetContactsUseCase(this._repository);

  final DataCollectionRepository _repository;

  Future<List<ContactEntity>> execute() async {
    return _repository.getContacts();
  }
}
