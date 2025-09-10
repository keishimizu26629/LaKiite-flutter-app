import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/value/user_id.dart';

void main() {
  group('UserId Value Object Tests', () {
    group('正常なケース', () {
      test('有効な形式のユーザーIDで作成できる', () {
        // Arrange
        const validIds = [
          'abcd1234',
          'ABCD1234',
          'aBcD1234',
          '12345678',
          'abcdefgh',
        ];

        // Act & Assert
        for (final validId in validIds) {
          expect(() => UserId(validId), returnsNormally);
          final userId = UserId(validId);
          expect(userId.value, validId);
          expect(userId.toString(), validId);
        }
      });

      test('同一の値を持つUserIdは等しい', () {
        // Arrange
        const testValue = 'test1234';

        // Act
        final userId1 = UserId(testValue);
        final userId2 = UserId(testValue);

        // Assert
        expect(userId1, equals(userId2));
        expect(userId1.hashCode, equals(userId2.hashCode));
      });

      test('異なる値を持つUserIdは等しくない', () {
        // Arrange
        final userId1 = UserId('test1234');
        final userId2 = UserId('abcd5678');

        // Act & Assert
        expect(userId1, isNot(equals(userId2)));
        expect(userId1.hashCode, isNot(equals(userId2.hashCode)));
      });
    });

    group('バリデーションテスト', () {
      test('有効な形式を正しく判定する', () {
        // Arrange
        const validFormats = [
          'abcd1234',
          'ABCD1234',
          'aBcD1234',
          '12345678',
          'abcdefgh',
          'ABCDEFGH',
          'a1b2c3d4',
        ];

        // Act & Assert
        for (final format in validFormats) {
          expect(UserId.isValidFormat(format), isTrue,
              reason: '$format should be valid');
        }
      });

      test('無効な形式を正しく判定する', () {
        // Arrange
        const invalidFormats = [
          '', // 空文字
          'abc123', // 6文字（短い）
          'abcd12345', // 9文字（長い）
          'abcd123@', // 特殊文字
          'abcd 123', // スペース
          'あいうえ1234', // 日本語
          'ABCD-123', // ハイフン
          'abcd_123', // アンダースコア
          'abcd.123', // ドット
        ];

        // Act & Assert
        for (final format in invalidFormats) {
          expect(UserId.isValidFormat(format), isFalse,
              reason: '$format should be invalid');
        }
      });
    });

    group('エラーケース', () {
      test('無効な形式でArgumentErrorが発生する', () {
        // Arrange
        const invalidFormats = [
          '', // 空文字
          'abc123', // 短すぎる
          'abcd12345', // 長すぎる
          'abcd123@', // 特殊文字
          'abcd 123', // スペース
        ];

        // Act & Assert
        for (final invalidFormat in invalidFormats) {
          expect(
            () => UserId(invalidFormat),
            throwsArgumentError,
            reason: '$invalidFormat should throw ArgumentError',
          );
        }
      });

      test('ArgumentErrorのメッセージが適切', () {
        // Act & Assert
        expect(
          () => UserId('invalid@id'),
          throwsA(
            predicate((e) =>
                e is ArgumentError && e.message == 'Invalid user ID format'),
          ),
        );
      });
    });

    group('境界値テスト', () {
      test('8文字ちょうどの英数字は有効', () {
        // Arrange
        const boundaryValidCases = [
          '12345678', // 数字のみ
          'abcdefgh', // 英字（小文字）のみ
          'ABCDEFGH', // 英字（大文字）のみ
          'a1b2c3d4', // 英数字混合
        ];

        // Act & Assert
        for (final testCase in boundaryValidCases) {
          expect(() => UserId(testCase), returnsNormally);
          expect(testCase.length, 8);
        }
      });

      test('7文字以下は無効', () {
        // Arrange
        const boundaryInvalidCases = [
          'a', // 1文字
          'ab', // 2文字
          'abcdefg', // 7文字
        ];

        // Act & Assert
        for (final testCase in boundaryInvalidCases) {
          expect(() => UserId(testCase), throwsArgumentError);
          expect(testCase.length, lessThan(8));
        }
      });

      test('9文字以上は無効', () {
        // Arrange
        const boundaryInvalidCases = [
          'abcdefghi', // 9文字
          'abcdefghij', // 10文字
          'abcdefghijklmnop', // 16文字
        ];

        // Act & Assert
        for (final testCase in boundaryInvalidCases) {
          expect(() => UserId(testCase), throwsArgumentError);
          expect(testCase.length, greaterThan(8));
        }
      });
    });
  });
}
