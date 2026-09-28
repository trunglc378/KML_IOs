import 'package:flutter_test/flutter_test.dart';
import 'package:kml_ios/core/constants/telegram_config.dart';

/// Ca kiem chung quan trong nhat cua buoc 4 (TC-IO-BUILD-03):
/// moi flavor chi chap nhan chat_id cua chinh minh.
///
/// Vi 'flavor' la const tu dart-define, ca nay duoc chay hai lan:
///   flutter test test/core/telegram_config_whitelist_test.dart
///   flutter test --dart-define=FLAVOR=prod test/core/telegram_config_whitelist_test.dart
///
/// Test tu phat hien flavor dang chay va khang dinh dung tap whitelist
/// tuong ung, nen cung mot file chay dung o ca hai lan.
void main() {
  group('TelegramConfig whitelist theo flavor', () {
    test('whitelist khop voi flavor dang chay', () {
      switch (TelegramConfig.flavor) {
        case 'prod':
          expect(TelegramConfig.whitelist, ['-5022357153']);
        case 'staging':
          expect(TelegramConfig.whitelist, ['-5152160106']);
        case 'dev':
          expect(TelegramConfig.whitelist, ['5887530234']);
      }
    });

    test('isAllowedChat chan chat_id cua flavor khac', () {
      // Ba chat_id da chot trong SDS 11.2.1.
      const devChat = '5887530234';
      const stagingChat = '-5152160106';
      const prodChat = '-5022357153';

      switch (TelegramConfig.flavor) {
        case 'prod':
          expect(TelegramConfig.isAllowedChat(prodChat), isTrue);
          expect(TelegramConfig.isAllowedChat(devChat), isFalse);
          expect(TelegramConfig.isAllowedChat(stagingChat), isFalse);
        case 'staging':
          expect(TelegramConfig.isAllowedChat(stagingChat), isTrue);
          expect(TelegramConfig.isAllowedChat(devChat), isFalse);
          expect(TelegramConfig.isAllowedChat(prodChat), isFalse);
        case 'dev':
          expect(TelegramConfig.isAllowedChat(devChat), isTrue);
          expect(TelegramConfig.isAllowedChat(prodChat), isFalse);
          expect(TelegramConfig.isAllowedChat(stagingChat), isFalse);
      }
    });
  });
}
