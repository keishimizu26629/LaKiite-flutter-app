import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/application/notification/accept_friend_request_use_case.dart';
import 'package:lakiite/domain/entity/notification.dart';

import '../../mock/repository/mock_notification_repository.dart';

void main() {
  group('AcceptFriendRequestUseCase', () {
    late MockNotificationRepository notificationRepository;
    late AcceptFriendRequestUseCase useCase;

    setUp(() {
      notificationRepository = MockNotificationRepository();
      useCase = AcceptFriendRequestUseCase(
        notificationRepository: notificationRepository,
      );
    });

    test('友達申請承認は相手の非公開プロフィールを読まず通知を承認済みにする', () async {
      notificationRepository.addTestNotification(
        _friendRequest(
          id: 'friend-request-id',
          sendUserId: 'sender-id',
          receiveUserId: 'receiver-id',
        ),
      );

      await useCase.execute('friend-request-id');

      final notification =
          await notificationRepository.getNotification('friend-request-id');

      expect(notification?.status, NotificationStatus.accepted);
      expect(notification?.isRead, isTrue);
    });
  });
}

Notification _friendRequest({
  required String id,
  required String sendUserId,
  required String receiveUserId,
}) {
  return Notification(
    id: id,
    type: NotificationType.friend,
    sendUserId: sendUserId,
    receiveUserId: receiveUserId,
    sendUserDisplayName: '申請者',
    receiveUserDisplayName: '受信者',
    status: NotificationStatus.pending,
    createdAt: DateTime(2026, 5, 22),
    updatedAt: DateTime(2026, 5, 22),
  );
}
