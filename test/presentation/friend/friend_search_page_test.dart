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
import 'package:lakiite/domain/interfaces/i_friend_invite_link_service.dart';
import 'package:lakiite/domain/interfaces/i_growth_analytics.dart';
import 'package:lakiite/infrastructure/friend_invite_link_service.dart';
import 'package:lakiite/infrastructure/providers.dart' as infrastructure;
import 'package:lakiite/presentation/friend/friend_search_page.dart';

import '../../mock/repository/mock_notification_repository.dart';
import '../../mock/repository/mock_user_repository.dart';
import '../../mock/analytics/recording_growth_analytics.dart';

class _StubAuthNotifier extends auth.AuthNotifier {
  _StubAuthNotifier(this._state);

  final AuthState _state;

  @override
  FutureOr<AuthState> build() => _state;
}

class _MutableAuthNotifier extends auth.AuthNotifier {
  _MutableAuthNotifier(this._initialState);

  final AuthState _initialState;

  @override
  FutureOr<AuthState> build() => _initialState;

  void authenticate(UserModel user) {
    state = AsyncData(AuthState.authenticated(user));
  }
}

class _StubFriendInviteLinkService implements IFriendInviteLinkService {
  _StubFriendInviteLinkService(this.inviteLink);

  final Uri inviteLink;

  @override
  Future<Uri> createInviteLink() async => inviteLink;
}

class _FailingFriendInviteLinkService implements IFriendInviteLinkService {
  @override
  Future<Uri> createInviteLink() async {
    throw const FriendInviteLinkException('link failed');
  }
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

    testWidgets('自分のQRには案内文と中央アイコンを表示しURLは表示しない', (tester) async {
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
      final inviteLink = Uri.parse(
        'https://lakiite-dev.inoworl.com/friend_cached',
      );
      final analytics = RecordingGrowthAnalytics();

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
            infrastructure.friendInviteLinkServiceProvider.overrideWithValue(
              _StubFriendInviteLinkService(inviteLink),
            ),
            growthAnalyticsProvider.overrideWithValue(analytics),
          ],
          child: const MaterialApp(home: FriendSearchPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('自分のQR'), findsOneWidget);
      expect(find.text('QRを読み取る'), findsOneWidget);

      await tester.tap(find.text('自分のQR'));
      await tester.pumpAndSettle();

      expect(
        find.text('QRコードを友達に読み込んでもらうと、フレンド追加できます'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('friend-search-qr-center-icon')),
          findsOneWidget);
      expect(find.text(inviteLink.toString()), findsNothing);
      expect(find.text('@${currentUser.searchId}'), findsNothing);
      expect(analytics.inviteLinkSurfaces, [FriendInviteSurface.qr]);
    });

    testWidgets('共有成功時はリンク作成と共有シート表示完了を記録する', (tester) async {
      final currentUser = UserModel.create(
        id: 'current-user-id',
        name: '現在ユーザー',
        displayName: '現在ユーザー',
      );
      final analytics = RecordingGrowthAnalytics();
      var shareCallCount = 0;

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
            infrastructure.friendInviteLinkServiceProvider.overrideWithValue(
              _StubFriendInviteLinkService(
                Uri.parse('https://lakiite.inoworl.com/friend_cached'),
              ),
            ),
            infrastructure.friendInviteShareProvider.overrideWithValue(
              (params) async {
                shareCallCount += 1;
              },
            ),
            growthAnalyticsProvider.overrideWithValue(analytics),
          ],
          child: const MaterialApp(home: FriendSearchPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('友人をアプリに招待する'));
      await tester.pumpAndSettle();

      expect(shareCallCount, 1);
      expect(analytics.inviteLinkSurfaces, [FriendInviteSurface.share]);
      expect(analytics.inviteShareSheetOpenedCount, 1);
    });

    testWidgets('リンク生成失敗時は招待イベントを記録しない', (tester) async {
      final currentUser = UserModel.create(
        id: 'current-user-id',
        name: '現在ユーザー',
        displayName: '現在ユーザー',
      );
      final analytics = RecordingGrowthAnalytics();

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
            infrastructure.friendInviteLinkServiceProvider.overrideWithValue(
              _FailingFriendInviteLinkService(),
            ),
            growthAnalyticsProvider.overrideWithValue(analytics),
          ],
          child: const MaterialApp(home: FriendSearchPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('自分のQR'));
      await tester.pumpAndSettle();

      expect(analytics.inviteLinkSurfaces, isEmpty);
      expect(analytics.inviteShareSheetOpenedCount, 0);
    });

    testWidgets('共有API失敗時はリンク作成だけを記録する', (tester) async {
      final currentUser = UserModel.create(
        id: 'current-user-id',
        name: '現在ユーザー',
        displayName: '現在ユーザー',
      );
      final analytics = RecordingGrowthAnalytics();

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
            infrastructure.friendInviteLinkServiceProvider.overrideWithValue(
              _StubFriendInviteLinkService(
                Uri.parse('https://lakiite.inoworl.com/friend_cached'),
              ),
            ),
            infrastructure.friendInviteShareProvider.overrideWithValue(
              (params) async => throw StateError('share failed'),
            ),
            growthAnalyticsProvider.overrideWithValue(analytics),
          ],
          child: const MaterialApp(home: FriendSearchPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('友人をアプリに招待する'));
      await tester.pumpAndSettle();

      expect(analytics.inviteLinkSurfaces, [FriendInviteSurface.share]);
      expect(analytics.inviteShareSheetOpenedCount, 0);
    });

    testWidgets('ログインユーザーの検索IDがある場合は友人をアプリに招待するボタンを表示する', (tester) async {
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

      expect(find.text('友人をアプリに招待する'), findsOneWidget);
      expect(
        find.text(
          'アプリをまだ使っていない人にも、すでに使っている人にも、フレンド追加の招待を送れます。',
        ),
        findsOneWidget,
      );
      expect(find.text('友人を招待する'), findsNothing);
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

    testWidgets('初期検索IDがある場合は友達申請できる検索結果を表示する', (tester) async {
      final friend = UserModel.create(
        id: 'friend-user-id',
        name: '招待ユーザー',
        displayName: '招待ユーザー',
      );
      final currentUser = UserModel.create(
        id: 'current-user-id',
        name: '現在ユーザー',
        displayName: '現在ユーザー',
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
          child: MaterialApp(
            home: FriendSearchPage(
              initialSearchId: friend.searchId.toString(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('招待ユーザー'), findsWidgets);
      expect(find.text('申請する'), findsOneWidget);
      expect(find.text('追加済み'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty,
      );
    });

    testWidgets('初期検索IDは認証ユーザー情報が準備できてから検索する', (tester) async {
      final friend = UserModel.create(
        id: 'friend-user-id',
        name: '招待ユーザー',
        displayName: '招待ユーザー',
      );
      final currentUser = UserModel.create(
        id: 'current-user-id',
        name: '現在ユーザー',
        displayName: '現在ユーザー',
      );
      final userRepository = MockUserRepository()
        ..addTestUser(currentUser)
        ..addTestUser(friend);
      late _MutableAuthNotifier authNotifier;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auth.authNotifierProvider.overrideWith(
              () => authNotifier =
                  _MutableAuthNotifier(AuthState.unauthenticated()),
            ),
            userRepositoryProvider.overrideWithValue(userRepository),
            notificationRepositoryProvider.overrideWithValue(
              MockNotificationRepository(),
            ),
            notification.unreadNotificationCountByTypeProvider.overrideWith(
              (ref, domain.NotificationType type) => Stream.value(0),
            ),
          ],
          child: MaterialApp(
            home: FriendSearchPage(
              initialSearchId: friend.searchId.toString(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('招待ユーザー'), findsNothing);

      authNotifier.authenticate(currentUser);
      await tester.pumpAndSettle();

      expect(find.text('招待ユーザー'), findsWidgets);
      expect(find.text('申請する'), findsOneWidget);
    });

    testWidgets('初期検索IDが自分自身の場合はエラーではなく案内を表示する', (tester) async {
      final currentUser = UserModel.create(
        id: 'current-user-id',
        name: '現在ユーザー',
        displayName: '現在ユーザー',
      );
      final userRepository = MockUserRepository()..addTestUser(currentUser);

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
          child: MaterialApp(
            home: FriendSearchPage(
              initialSearchId: currentUser.searchId.toString(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('自分自身は友達に追加できません'), findsOneWidget);
      expect(find.textContaining('エラー:'), findsNothing);
      expect(find.text('申請する'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        isEmpty,
      );
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
