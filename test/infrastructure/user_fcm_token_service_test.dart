import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/infrastructure/user_fcm_token_service.dart';

void main() {
  group('UserFcmTokenService.extractFcmTokens', () {
    test('platform別トークンとlegacyトークンを重複排除して返す', () {
      final tokens = UserFcmTokenService.extractFcmTokens({
        'fcmToken': 'legacy-ios-token',
        'fcmTokens': {
          'android': {
            'token': 'android-token',
            'platform': 'android',
          },
          'ios': {
            'token': 'legacy-ios-token',
            'platform': 'ios',
          },
        },
      });

      expect(tokens, ['android-token', 'legacy-ios-token']);
    });

    test('legacyトークンのみの既存データも読み込める', () {
      final tokens = UserFcmTokenService.extractFcmTokens({
        'fcmToken': 'legacy-token',
      });

      expect(tokens, ['legacy-token']);
    });

    test('空文字や不正な形式は除外する', () {
      final tokens = UserFcmTokenService.extractFcmTokens({
        'fcmToken': '',
        'fcmTokens': {
          'android': {'token': ''},
          'ios': {'value': 'missing-token-key'},
          'web': 'web-token',
        },
      });

      expect(tokens, ['web-token']);
    });
  });
}
