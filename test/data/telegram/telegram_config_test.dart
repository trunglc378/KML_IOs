import 'package:flutter_test/flutter_test.dart';
import 'package:kml_ios/core/constants/telegram_config.dart';

void main() {
  group('TelegramConfig validation & constants tests', () {
    test('General constants adhere to Bot API limits', () {
      expect(TelegramConfig.apiBase, equals('https://api.telegram.org'));
      expect(TelegramConfig.maxMessageLength, equals(4096));
      expect(TelegramConfig.maxUploadBytes, equals(50 * 1024 * 1024));
      expect(TelegramConfig.maxPhotoBytes, equals(10 * 1024 * 1024));
      expect(TelegramConfig.connectTimeout, equals(const Duration(seconds: 10)));
      expect(TelegramConfig.sendTimeout, equals(const Duration(seconds: 60)));
      expect(TelegramConfig.backoffCap, equals(const Duration(minutes: 2)));
    });

    test('Default flavor is dev and whitelist contains dev chat_id', () {
      expect(TelegramConfig.flavor, equals('dev'));
      expect(TelegramConfig.whitelist, contains('5887530234'));
      expect(TelegramConfig.isAllowedChat('5887530234'), isTrue);
    });

    test('Blocked test chat ID is not allowed in current flavor', () {
      const blockedChat = '8178322761';
      expect(TelegramConfig.isAllowedChat(blockedChat), isFalse);
    });

    test('Supergroup negative chat ID from staging or prod is blocked on dev flavor', () {
      const stagingGroup = '-5152160106';
      const prodGroup = '-5022357153';
      expect(TelegramConfig.isAllowedChat(stagingGroup), isFalse);
      expect(TelegramConfig.isAllowedChat(prodGroup), isFalse);
    });
  });
}
