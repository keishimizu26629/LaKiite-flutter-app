import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/value/user_id.dart';
import '../../mock/base_mock.dart';

void main() {
  group('UserModel Entity Tests', () {
    group('UserModel.create ファクトリメソッド', () {
      test('必須パラメータでユーザーが正常に作成される', () {
        // Arrange
        const id = 'test-user-123';
        const name = 'テストユーザー';

        // Act
        final user = UserModel.create(
          id: id,
          name: name,
        );

        // Assert
        expect(user.id, id);
        expect(user.name, name);
        expect(user.displayName, name); // displayNameが指定されていない場合はnameが使用される
        expect(user.publicProfile.id, id);
        expect(user.privateProfile.id, id);
        expect(user.privateProfile.name, name);
        expect(user.friends, isEmpty);
        expect(user.groups, isEmpty);
        expect(user.iconUrl, isNull);
        expect(user.createdAt, isNotNull);
        expect(user.searchId, isNotNull);
      });

      test('displayNameが指定された場合に正しく設定される', () {
        // Arrange
        const id = 'test-user-123';
        const name = 'テストユーザー';
        const displayName = 'カスタム表示名';

        // Act
        final user = UserModel.create(
          id: id,
          name: name,
          displayName: displayName,
        );

        // Assert
        expect(user.name, name);
        expect(user.displayName, displayName);
        expect(user.publicProfile.displayName, displayName);
      });

      test('作成時にsearchIdが自動生成される', () {
        // Act
        final user1 = UserModel.create(id: 'user1', name: 'ユーザー1');
        final user2 = UserModel.create(id: 'user2', name: 'ユーザー2');

        // Assert
        expect(user1.searchId, isNotNull);
        expect(user2.searchId, isNotNull);
        expect(
            user1.searchId, isNot(equals(user2.searchId))); // 異なるsearchIdが生成される
        expect(user1.searchId.toString().length, 8); // 8文字のID
        expect(user2.searchId.toString().length, 8);
      });

      test('作成時刻が現在時刻に近い値になる', () {
        // Arrange
        final beforeCreation = DateTime.now();

        // Act
        final user = UserModel.create(id: 'test', name: 'テスト');

        // Assert
        final afterCreation = DateTime.now();
        expect(user.createdAt.isAfter(beforeCreation), isTrue);
        expect(user.createdAt.isBefore(afterCreation), isTrue);
      });
    });

    group('UserModel プロパティアクセス', () {
      late UserModel testUser;

      setUp(() {
        testUser = BaseMock.createTestUser(
          id: 'test-user-123',
          name: 'テストユーザー',
          displayName: 'テスト表示名',
        );
      });

      test('各プロパティが正しくアクセスできる', () {
        // Assert
        expect(testUser.id, 'test-user-123');
        expect(testUser.name, 'テストユーザー');
        expect(testUser.displayName, 'テスト表示名');
        expect(testUser.friends, isEmpty);
        expect(testUser.groups, isEmpty);
        expect(testUser.iconUrl, isNull);
        expect(testUser.createdAt, isNotNull);
        expect(testUser.searchId, isNotNull);
      });

      test('publicProfileとprivateProfileから正しく値が取得される', () {
        // Assert
        expect(testUser.id, testUser.privateProfile.id);
        expect(testUser.name, testUser.privateProfile.name);
        expect(testUser.displayName, testUser.publicProfile.displayName);
        expect(testUser.friends, testUser.privateProfile.friends);
        expect(testUser.groups, testUser.privateProfile.groups);
        expect(testUser.iconUrl, testUser.publicProfile.iconUrl);
        expect(testUser.createdAt, testUser.privateProfile.createdAt);
        expect(testUser.searchId, testUser.publicProfile.searchId);
      });
    });

    group('updateProfile メソッド', () {
      late UserModel originalUser;

      setUp(() {
        originalUser = BaseMock.createTestUser(
          id: 'test-user-123',
          name: 'オリジナル名前',
          displayName: 'オリジナル表示名',
        );
      });

      test('nameのみ更新される', () {
        // Arrange
        const newName = '新しい名前';

        // Act
        final updatedUser = originalUser.updateProfile(name: newName);

        // Assert
        expect(updatedUser.name, newName);
        expect(updatedUser.displayName, originalUser.displayName); // 他は変更されない
        expect(updatedUser.id, originalUser.id);
        expect(updatedUser.searchId, originalUser.searchId);
      });

      test('displayNameのみ更新される', () {
        // Arrange
        const newDisplayName = '新しい表示名';

        // Act
        final updatedUser =
            originalUser.updateProfile(displayName: newDisplayName);

        // Assert
        expect(updatedUser.displayName, newDisplayName);
        expect(updatedUser.name, originalUser.name); // 他は変更されない
        expect(updatedUser.id, originalUser.id);
        expect(updatedUser.searchId, originalUser.searchId);
      });

      test('複数のプロパティが同時に更新される', () {
        // Arrange
        const newName = '新しい名前';
        const newDisplayName = '新しい表示名';
        const newIconUrl = 'https://example.com/icon.jpg';
        const newShortBio = '新しい自己紹介';
        final newSearchId = UserId('newid123');

        // Act
        final updatedUser = originalUser.updateProfile(
          name: newName,
          displayName: newDisplayName,
          searchId: newSearchId,
          iconUrl: newIconUrl,
          shortBio: newShortBio,
        );

        // Assert
        expect(updatedUser.name, newName);
        expect(updatedUser.displayName, newDisplayName);
        expect(updatedUser.searchId, newSearchId);
        expect(updatedUser.iconUrl, newIconUrl);
        expect(updatedUser.publicProfile.shortBio, newShortBio);
        expect(updatedUser.id, originalUser.id); // IDは変更されない
        expect(updatedUser.createdAt, originalUser.createdAt); // 作成日時も変更されない
      });

      test('nullを渡した場合は元の値が保持される', () {
        // Act
        final updatedUser = originalUser.updateProfile(
          name: null,
          displayName: null,
          searchId: null,
          iconUrl: null,
          shortBio: null,
        );

        // Assert
        expect(updatedUser.name, originalUser.name);
        expect(updatedUser.displayName, originalUser.displayName);
        expect(updatedUser.searchId, originalUser.searchId);
        expect(updatedUser.iconUrl, originalUser.iconUrl);
        expect(updatedUser.publicProfile.shortBio,
            originalUser.publicProfile.shortBio);
      });

      test('イミュータブルであることを確認（元のオブジェクトは変更されない）', () {
        // Arrange
        const newName = '新しい名前';
        final originalName = originalUser.name;

        // Act
        final updatedUser = originalUser.updateProfile(name: newName);

        // Assert
        expect(originalUser.name, originalName); // 元のオブジェクトは変更されない
        expect(updatedUser.name, newName);
        expect(originalUser, isNot(same(updatedUser))); // 異なるインスタンス
      });
    });

    group('updateFcmToken メソッド', () {
      late UserModel originalUser;

      setUp(() {
        originalUser = BaseMock.createTestUser();
      });

      test('FCMトークンが正しく更新される', () {
        // Arrange
        const newToken = 'new-fcm-token-123';

        // Act
        final updatedUser = originalUser.updateFcmToken(newToken);

        // Assert
        expect(updatedUser.fcmToken, newToken);
        expect(updatedUser.privateProfile.fcmToken, newToken);
      });

      test('FCMトークンをnullに設定できる', () {
        // Arrange
        final userWithToken = originalUser.updateFcmToken('some-token');

        // Act
        final updatedUser = userWithToken.updateFcmToken(null);

        // Assert
        expect(updatedUser.fcmToken, isNull);
        expect(updatedUser.privateProfile.fcmToken, isNull);
      });

      test('FCMトークン以外のプロパティは変更されない', () {
        // Arrange
        const newToken = 'new-fcm-token-123';

        // Act
        final updatedUser = originalUser.updateFcmToken(newToken);

        // Assert
        expect(updatedUser.id, originalUser.id);
        expect(updatedUser.name, originalUser.name);
        expect(updatedUser.displayName, originalUser.displayName);
        expect(updatedUser.searchId, originalUser.searchId);
        expect(updatedUser.friends, originalUser.friends);
        expect(updatedUser.groups, originalUser.groups);
        expect(updatedUser.createdAt, originalUser.createdAt);
      });

      test('イミュータブルであることを確認', () {
        // Arrange
        const newToken = 'new-fcm-token-123';

        // Act
        final updatedUser = originalUser.updateFcmToken(newToken);

        // Assert
        expect(originalUser.fcmToken, isNull); // 元のオブジェクトは変更されない
        expect(updatedUser.fcmToken, newToken);
        expect(originalUser, isNot(same(updatedUser)));
      });
    });

    group('SearchUserModel', () {
      test('UserModelからSearchUserModelが正しく作成される', () {
        // Arrange
        final user = BaseMock.createTestUser(
          id: 'test-123',
          name: 'テストユーザー',
          displayName: 'テスト表示名',
        );

        // Act
        final searchUser = SearchUserModel.fromUserModel(user);

        // Assert
        expect(searchUser.id, user.id);
        expect(searchUser.displayName, user.displayName);
        expect(searchUser.searchId, user.searchId.toString());
        expect(searchUser.iconUrl, user.iconUrl);
        expect(searchUser.shortBio, user.publicProfile.shortBio);
      });

      test('Firestoreデータから正しく作成される', () {
        // Arrange
        const id = 'firestore-user-123';
        const data = {
          'displayName': 'Firestoreユーザー',
          'searchId': 'fsuser12',
          'iconUrl': 'https://example.com/icon.jpg',
          'shortBio': 'Firestore経由のユーザー',
        };

        // Act
        final searchUser = SearchUserModel.fromFirestore(id, data);

        // Assert
        expect(searchUser.id, id);
        expect(searchUser.displayName, 'Firestoreユーザー');
        expect(searchUser.searchId, 'fsuser12');
        expect(searchUser.iconUrl, 'https://example.com/icon.jpg');
        expect(searchUser.shortBio, 'Firestore経由のユーザー');
      });
    });
  });
}
