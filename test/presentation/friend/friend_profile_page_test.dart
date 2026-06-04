import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart' as auth;
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/calendar/schedule_providers.dart';
import 'package:lakiite/presentation/friend/friend_profile_page.dart';
import 'package:lakiite/presentation/friend/friend_providers.dart';

import '../../mock/repository/mock_user_repository.dart';

class _StubAuthNotifier extends auth.AuthNotifier {
  _StubAuthNotifier(this._state);

  final AuthState _state;

  @override
  FutureOr<AuthState> build() => _state;
}

class _RecordingUserRepository extends MockUserRepository {
  final removedFriends = <String>[];

  @override
  Future<void> removeFriend(String userId, String friendId) async {
    removedFriends.add('$userId:$friendId');
  }
}

void main() {
  group('FriendProfilePage', () {
    testWidgets('AppBarのゴミ箱からフレンド削除を実行する', (tester) async {
      final currentUser = UserModel.create(
        id: 'current-user-id',
        name: '現在ユーザー',
        displayName: '現在ユーザー',
      );
      final friend = UserModel.create(
        id: 'friend-id',
        name: '友達一郎',
        displayName: '友達一郎',
      );
      final userRepository = _RecordingUserRepository()..addTestUser(friend);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auth.authNotifierProvider.overrideWith(
              () => _StubAuthNotifier(AuthState.authenticated(currentUser)),
            ),
            userRepositoryProvider.overrideWithValue(userRepository),
            userFriendsStreamProvider.overrideWith(
              (ref) => Stream.value([friend.publicProfile]),
            ),
            userSchedulesStreamProvider.overrideWith(
              (ref, userId) => Stream.value(const <Schedule>[]),
            ),
          ],
          child: const MaterialApp(
            home: FriendProfilePage(userId: 'friend-id'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final deleteButton = find.byTooltip('フレンドを削除');
      expect(deleteButton, findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      expect(find.text('フレンドから削除しますか？'), findsOneWidget);

      await tester.tap(find.text('削除'));
      await tester.pumpAndSettle();

      expect(userRepository.removedFriends, ['current-user-id:friend-id']);
      expect(find.text('フレンドから削除しました'), findsOneWidget);
    });
  });
}
