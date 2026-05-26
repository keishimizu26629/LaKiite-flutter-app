import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/notification/notification_notifier.dart'
    as notification_app;
import 'package:lakiite/domain/entity/notification.dart' as domain;
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/infrastructure/firebase/push_notification_sender.dart';
import 'package:lakiite/presentation/notification/notification_list_page.dart';

import '../../mock/repository/mock_notification_repository.dart';
import '../../mock/repository/mock_user_repository.dart';

void main() {
  group('NotificationListPage', () {
    late MockNotificationRepository notificationRepository;
    late MockUserRepository userRepository;
    late UserModel currentUser;
    late domain.Notification friendRequest;

    setUp(() {
      notificationRepository = MockNotificationRepository();
      userRepository = MockUserRepository();
      currentUser = UserModel.create(
        id: 'receiver-id',
        name: '受信者',
        displayName: '受信者',
      );
      friendRequest = domain.Notification(
        id: 'friend-request-id',
        type: domain.NotificationType.friend,
        sendUserId: 'sender-id',
        receiveUserId: currentUser.id,
        sendUserDisplayName: '申請者',
        receiveUserDisplayName: currentUser.displayName,
        status: domain.NotificationStatus.pending,
        createdAt: DateTime(2026, 5, 27),
        updatedAt: DateTime(2026, 5, 27),
      );

      userRepository.addTestUser(currentUser);
      userRepository.addTestUser(
        UserModel.create(
          id: 'sender-id',
          name: '申請者',
          displayName: '申請者',
        ),
      );
      notificationRepository.addTestNotification(friendRequest);
    });

    testWidgets('フレンド申請通知の行タップではプロフィールへ遷移しない', (tester) async {
      final navigatorObserver = _RecordingNavigatorObserver();

      await tester.pumpWidget(
        _buildTestApp(
          currentUser: currentUser,
          notificationRepository: notificationRepository,
          userRepository: userRepository,
          navigatorObserver: navigatorObserver,
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      await tester.tap(find.text('フレンド申請'));
      await tester.pump();

      expect(navigatorObserver.pushedRoutes, isEmpty);
    });

    testWidgets('フレンド申請通知の承認ボタンは承認処理だけを実行する', (tester) async {
      final navigatorObserver = _RecordingNavigatorObserver();

      await tester.pumpWidget(
        _buildTestApp(
          currentUser: currentUser,
          notificationRepository: notificationRepository,
          userRepository: userRepository,
          navigatorObserver: navigatorObserver,
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));

      await tester.tap(find.widgetWithText(ElevatedButton, '承認'));
      await tester.pump(const Duration(milliseconds: 400));

      final acceptedNotification =
          notificationRepository.findTestNotification(friendRequest.id);

      expect(acceptedNotification?.status, domain.NotificationStatus.accepted);
      expect(navigatorObserver.pushedRoutes, isEmpty);
    });
  });
}

Widget _buildTestApp({
  required UserModel currentUser,
  required MockNotificationRepository notificationRepository,
  required MockUserRepository userRepository,
  required NavigatorObserver navigatorObserver,
}) {
  return ProviderScope(
    overrides: [
      authStateStreamProvider.overrideWith(
        (ref) => Stream.value(AuthState.authenticated(currentUser)),
      ),
      notification_app.currentUserIdProvider.overrideWithValue(currentUser.id),
      notification_app.notificationRepositoryProvider.overrideWithValue(
        notificationRepository,
      ),
      notification_app.pushNotificationSenderProvider.overrideWithValue(
        PushNotificationSender(
          cloudFunctionUrl: 'https://example.test/push',
          tokenResolver: (_) async => const [],
        ),
      ),
      userRepositoryProvider.overrideWithValue(userRepository),
    ],
    child: MaterialApp(
      navigatorObservers: [navigatorObserver],
      home: const NotificationListPage(),
    ),
  );
}

class _RecordingNavigatorObserver extends NavigatorObserver {
  final pushedRoutes = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      pushedRoutes.add(route);
    }
    super.didPush(route, previousRoute);
  }
}
