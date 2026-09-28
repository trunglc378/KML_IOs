import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'token_store.dart';

/// Provider cung cap mot TokenStore dung chung cho toan ung dung.
/// Dat o day (khong trong features) vi nhieu feature deu can doc cau hinh bot.
/// Luu y: provider chi tra ve doi tuong TokenStore; viec doc gia tri bi mat
/// la bat dong bo, nen noi dung thuc te duoc doc qua FutureProvider hoac
/// AsyncNotifier o tang tren.
final tokenStoreProvider = Provider<TokenStore>((Ref ref) {
  return TokenStore();
});
