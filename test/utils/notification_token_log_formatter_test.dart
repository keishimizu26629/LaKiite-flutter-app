import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/utils/notification_token_log_formatter.dart';

void main() {
  group('maskNotificationToken', () {
    test('長い通知トークンは先頭と末尾だけを残してマスクする', () {
      const token = 'abcdefghijklmnopqrstuvwxyz0123456789';

      expect(maskNotificationToken(token), 'abcdef...456789');
    });

    test('短い通知トークンも全文を出さずにマスクする', () {
      expect(maskNotificationToken('abcd'), 'ab...cd');
    });

    test('nullは未取得として表示する', () {
      expect(maskNotificationToken(null), '未取得');
    });
  });
}
