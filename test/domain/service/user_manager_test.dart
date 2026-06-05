import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/service/user_manager.dart';

import '../../mock/repository/mock_user_repository.dart';

void main() {
  group('UserManager', () {
    late MockUserRepository repository;
    late UserManager manager;

    setUp(() {
      repository = MockUserRepository();
      manager = UserManager(repository);
    });

    UserModel createUser({
      required String id,
      required String displayName,
      List<String> friends = const [],
    }) {
      final user = UserModel.create(
        id: id,
        name: displayName,
        displayName: displayName,
      );

      return user.copyWith(
        privateProfile: user.privateProfile.copyWith(friends: friends),
      );
    }

    test('getAuthenticatedUserFriends returns friends sorted by display name',
        () async {
      final currentUser = createUser(
        id: 'current-user',
        displayName: 'Current User',
        friends: const ['charlie-id', 'alice-id', 'bob-id'],
      );

      repository
        ..addTestUser(currentUser)
        ..addTestUser(createUser(id: 'charlie-id', displayName: 'Charlie'))
        ..addTestUser(createUser(id: 'alice-id', displayName: 'Alice'))
        ..addTestUser(createUser(id: 'bob-id', displayName: 'Bob'));

      final friends = await manager.getAuthenticatedUserFriends(currentUser.id);

      expect(
        friends.map((friend) => friend.displayName),
        ['Alice', 'Bob', 'Charlie'],
      );
    });

    test('watchAuthenticatedUserFriends emits friends sorted by display name',
        () async {
      final currentUser = createUser(
        id: 'current-user',
        displayName: 'Current User',
        friends: const ['charlie-id', 'alice-id', 'bob-id'],
      );

      repository
        ..addTestUser(currentUser)
        ..addTestUser(createUser(id: 'charlie-id', displayName: 'Charlie'))
        ..addTestUser(createUser(id: 'alice-id', displayName: 'Alice'))
        ..addTestUser(createUser(id: 'bob-id', displayName: 'Bob'));

      final friends =
          await manager.watchAuthenticatedUserFriends(currentUser.id).first;

      expect(
        friends.map((friend) => friend.displayName),
        ['Alice', 'Bob', 'Charlie'],
      );
    });
  });
}
