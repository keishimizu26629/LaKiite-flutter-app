import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart' as auth;
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/notification/notification_notifier.dart'
    as notification;
import 'package:lakiite/domain/entity/notification.dart' as domain;
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/friend/friend_search_page.dart';

import '../../mock/repository/mock_notification_repository.dart';
import '../../mock/repository/mock_user_repository.dart';

class _StubAuthNotifier extends auth.AuthNotifier {
  _StubAuthNotifier(this._state);

  final AuthState _state;

  @override
  FutureOr<AuthState> build() => _state;
}

void main() {
  group('FriendSearchPage', () {
    UserModel userWithFriends(UserModel user, List<String> friendIds) {
      return UserModel(
        publicProfile: user.publicProfile,
        privateProfile: PrivateUserModel(
          id: user.id,
          name: user.name,
          friends: friendIds,
          groups: user.groups,
          lists: user.privateProfile.lists,
          createdAt: user.createdAt,
          fcmToken: user.fcmToken,
        ),
      );
    }

    testWidgets('自分の検索ID QR表示とQR読み取りボタンを表示する', (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final currentUser = UserModel.create(
        id: 'current-user-id',
        name: '現在ユーザー',
        displayName: '現在ユーザー',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auth.authNotifierProvider.overrideWith(
              () => _StubAuthNotifier(AuthState.authenticated(currentUser)),
            ),
            userRepositoryProvider.overrideWithValue(MockUserRepository()),
            notificationRepositoryProvider.overrideWithValue(
              MockNotificationRepository(),
            ),
            notification.unreadNotificationCountByTypeProvider.overrideWith(
              (ref, domain.NotificationType type) => Stream.value(0),
            ),
          ],
          child: const MaterialApp(home: FriendSearchPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('自分のQR'), findsOneWidget);
      expect(find.text('QRを読み取る'), findsOneWidget);

      await tester.tap(find.text('自分のQR'));
      await tester.pumpAndSettle();

      expect(find.text('自分の検索ID'), findsNothing);
      expect(find.text('@${currentUser.searchId}'), findsNothing);
    });

    testWidgets('ログインユーザーの検索IDがある場合は友人招待ボタンを表示する', (tester) async {
      final currentUser = UserModel.create(
        id: 'current-user-id',
        name: '現在ユーザー',
        displayName: '現在ユーザー',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auth.authNotifierProvider.overrideWith(
              () => _StubAuthNotifier(AuthState.authenticated(currentUser)),
            ),
            userRepositoryProvider.overrideWithValue(MockUserRepository()),
            notificationRepositoryProvider.overrideWithValue(
              MockNotificationRepository(),
            ),
            notification.unreadNotificationCountByTypeProvider.overrideWith(
              (ref, domain.NotificationType type) => Stream.value(0),
            ),
          ],
          child: const MaterialApp(home: FriendSearchPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('友人を招待する'), findsOneWidget);
    });

    testWidgets('フレンド追加済みユーザー検索では申請ボタンを無効化する', (tester) async {
      final friend = UserModel.create(
        id: 'friend-user-id',
        name: 'フレンドユーザー',
        displayName: 'フレンドユーザー',
      );
      final currentUser = userWithFriends(
        UserModel.create(
          id: 'current-user-id',
          name: '現在ユーザー',
          displayName: '現在ユーザー',
        ),
        [friend.id],
      );
      final userRepository = MockUserRepository()
        ..addTestUser(currentUser)
        ..addTestUser(friend);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auth.authNotifierProvider.overrideWith(
              () => _StubAuthNotifier(AuthState.authenticated(currentUser)),
            ),
            userRepositoryProvider.overrideWithValue(userRepository),
            notificationRepositoryProvider.overrideWithValue(
              MockNotificationRepository(),
            ),
            notification.unreadNotificationCountByTypeProvider.overrideWith(
              (ref, domain.NotificationType type) => Stream.value(0),
            ),
          ],
          child: const MaterialApp(home: FriendSearchPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField), friend.searchId.toString());
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('追加済み'), findsOneWidget);
      expect(find.text('申請する'), findsNothing);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '追加済み'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('検索時はログイン時点ではなく最新の友達状態で追加済みを判定する', (tester) async {
      final friend = UserModel.create(
        id: 'friend-user-id',
        name: 'フレンドユーザー',
        displayName: 'フレンドユーザー',
      );
      final staleAuthUser = userWithFriends(
        UserModel.create(
          id: 'current-user-id',
          name: '現在ユーザー',
          displayName: '現在ユーザー',
        ),
        [friend.id],
      );
      final latestCurrentUser = userWithFriends(staleAuthUser, const []);
      final userRepository = MockUserRepository()
        ..addTestUser(latestCurrentUser)
        ..addTestUser(friend);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auth.authNotifierProvider.overrideWith(
              () => _StubAuthNotifier(AuthState.authenticated(staleAuthUser)),
            ),
            userRepositoryProvider.overrideWithValue(userRepository),
            notificationRepositoryProvider.overrideWithValue(
              MockNotificationRepository(),
            ),
            notification.unreadNotificationCountByTypeProvider.overrideWith(
              (ref, domain.NotificationType type) => Stream.value(0),
            ),
          ],
          child: const MaterialApp(home: FriendSearchPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField), friend.searchId.toString());
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('申請する'), findsOneWidget);
      expect(find.text('追加済み'), findsNothing);
    });
  });
}
