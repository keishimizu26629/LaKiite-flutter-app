import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/application/auth/auth_notifier.dart' as auth;
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/notification/notification_notifier.dart'
    as notification;
import 'package:lakiite/domain/entity/notification.dart' as domain;
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/friend/friend_list_page.dart';
import 'package:lakiite/presentation/friend/friend_providers.dart';

class _StubAuthNotifier extends auth.AuthNotifier {
  _StubAuthNotifier(this._state);

  final AuthState _state;

  @override
  FutureOr<AuthState> build() => _state;
}

void main() {
  group('FriendListPage', () {
    testWidgets('送信済みの保留中友達申請をフレンド一覧下の申請中セクションに表示する', (tester) async {
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
      final pendingRequest = domain.Notification.createFriendRequest(
        fromUserId: currentUser.id,
        toUserId: 'pending-friend-id',
        fromUserDisplayName: currentUser.displayName,
        toUserDisplayName: '申請先ユーザー',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auth.authNotifierProvider.overrideWith(
              () => _StubAuthNotifier(AuthState.authenticated(currentUser)),
            ),
            userFriendsStreamProvider.overrideWith(
              (ref) => Stream.value([friend.publicProfile]),
            ),
            notification.sentNotificationsByTypeProvider.overrideWith(
              (ref, type) => Stream.value([pendingRequest]),
            ),
            notification.unreadNotificationCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
            notification.unreadNotificationCountByTypeProvider.overrideWith(
              (ref, type) => Stream.value(0),
            ),
          ],
          child: const MaterialApp(home: FriendListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('友達一郎'), findsOneWidget);
      expect(find.text('申請中'), findsOneWidget);
      expect(find.text('申請先ユーザー'), findsOneWidget);
      expect(find.text('承認待ち'), findsOneWidget);
    });

    testWidgets('拒否済みの送信済み友達申請は申請中セクションに表示しない', (tester) async {
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
      final rejectedRequest = domain.Notification(
        id: 'rejected-request-id',
        type: domain.NotificationType.friend,
        sendUserId: currentUser.id,
        receiveUserId: 'rejected-friend-id',
        sendUserDisplayName: currentUser.displayName,
        receiveUserDisplayName: '拒否済みユーザー',
        status: domain.NotificationStatus.rejected,
        createdAt: DateTime(2026, 5, 27),
        updatedAt: DateTime(2026, 5, 27),
        rejectionCount: 1,
        isRead: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            auth.authNotifierProvider.overrideWith(
              () => _StubAuthNotifier(AuthState.authenticated(currentUser)),
            ),
            userFriendsStreamProvider.overrideWith(
              (ref) => Stream.value([friend.publicProfile]),
            ),
            notification.sentNotificationsByTypeProvider.overrideWith(
              (ref, type) => Stream.value([rejectedRequest]),
            ),
            notification.unreadNotificationCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
            notification.unreadNotificationCountByTypeProvider.overrideWith(
              (ref, type) => Stream.value(0),
            ),
          ],
          child: const MaterialApp(home: FriendListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('友達一郎'), findsOneWidget);
      expect(find.text('申請中'), findsNothing);
      expect(find.text('拒否済みユーザー'), findsNothing);
      expect(find.text('承認待ち'), findsNothing);
    });
  });
}
