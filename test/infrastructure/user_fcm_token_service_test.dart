import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/infrastructure/user_fcm_token_service.dart';

void main() {
  group('UserFcmTokenService.extractFcmTokens', () {
    test('fcmTokens配列から重複排除して返す', () {
      final tokens = UserFcmTokenService.extractFcmTokens({
        'fcmTokens': [
          'android-token',
          'ios-token',
          'android-token',
        ],
      });

      expect(tokens, ['android-token', 'ios-token']);
    });

    test('legacy fcmTokenのみの既存データは読み込まない', () {
      final tokens = UserFcmTokenService.extractFcmTokens({
        'fcmToken': 'legacy-token',
      });

      expect(tokens, isEmpty);
    });

    test('空文字や不正な形式は除外する', () {
      final tokens = UserFcmTokenService.extractFcmTokens({
        'fcmToken': '',
        'fcmTokens': [
          '',
          123,
          'web-token',
        ],
      });

      expect(tokens, ['web-token']);
    });
  });
}
