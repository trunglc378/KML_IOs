import 'package:flutter_test/flutter_test.dart';
import 'package:kml_ios/core/security/token_store.dart';

void main() {
  group('TokenStore.maskToken', () {
    test('giu bot_id, che secret', () {
      expect(TokenStore.maskToken('8920168927:AAEabcXYZ'), '8920168927:*');
    });

    test('chuoi khong co dau hai cham tra ve *', () {
      expect(TokenStore.maskToken('khongcodau'), '*');
    });
  });

  group('TokenStore.maskChatId', () {
    test('chat ca nhan giu 4 ky tu cuoi', () {
      expect(TokenStore.maskChatId('5887530234'), '*0234');
    });

    test('chat group so am giu 4 ky tu cuoi', () {
      expect(TokenStore.maskChatId('-5022357153'), '*7153');
    });

    test('chuoi ngan hon 4 ky tu tra ve *', () {
      expect(TokenStore.maskChatId('123'), '***');
    });
  });
}
