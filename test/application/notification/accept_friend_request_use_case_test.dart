import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/application/notification/accept_friend_request_use_case.dart';
import 'package:lakiite/domain/entity/notification.dart';

import '../../mock/base_mock.dart';
import '../../mock/repository/mock_notification_repository.dart';
import '../../mock/repository/mock_user_repository.dart';

void main() {
  group('AcceptFriendRequestUseCase', () {
    late MockUserRepository userRepository;
    late MockNotificationRepository notificationRepository;
    late AcceptFriendRequestUseCase useCase;

    setUp(() {
      userRepository = MockUserRepository();
      notificationRepository = MockNotificationRepository();
      useCase = AcceptFriendRequestUseCase(
        notificationRepository: notificationRepository,
        userRepository: userRepository,
      );
    });

    test('申請元と受信者が存在する場合は双方を友達にして通知を承認済みにする', () async {
      final sender = BaseMock.createTestUser(
        id: 'sender-id',
        name: '申請者',
        displayName: '申請者',
      );
      final receiver = BaseMock.createTestUser(
        id: 'receiver-id',
        name: '受信者',
        displayName: '受信者',
      );
      userRepository
        ..addTestUser(sender)
        ..addTestUser(receiver);
      notificationRepository.addTestNotification(
        _friendRequest(
          id: 'friend-request-id',
          sendUserId: sender.id,
          receiveUserId: receiver.id,
        ),
      );

      await useCase.execute('friend-request-id');

      final notification =
          await notificationRepository.getNotification('friend-request-id');
      final updatedSender = await userRepository.getUser(sender.id);
      final updatedReceiver = await userRepository.getUser(receiver.id);

      expect(notification?.status, NotificationStatus.accepted);
      expect(notification?.isRead, isTrue);
      expect(updatedSender?.friends, contains(receiver.id));
      expect(updatedReceiver?.friends, contains(sender.id));
    });

    test('申請元が削除済みの場合は友達追加せず通知を期限切れとして既読にする', () async {
      final receiver = BaseMock.createTestUser(
        id: 'receiver-id',
        name: '受信者',
        displayName: '受信者',
      );
      userRepository.addTestUser(receiver);
      notificationRepository.addTestNotification(
        _friendRequest(
          id: 'deleted-sender-request-id',
          sendUserId: 'deleted-sender-id',
          receiveUserId: receiver.id,
        ),
      );

      await useCase.execute('deleted-sender-request-id');

      final notification = await notificationRepository
          .getNotification('deleted-sender-request-id');
      final updatedReceiver = await userRepository.getUser(receiver.id);

      expect(notification?.status, NotificationStatus.expired);
      expect(notification?.isRead, isTrue);
      expect(updatedReceiver?.friends, isNot(contains('deleted-sender-id')));
    });

    test('受信者が削除済みの場合は友達追加せず通知を期限切れとして既読にする', () async {
      final sender = BaseMock.createTestUser(
        id: 'sender-id',
        name: '申請者',
        displayName: '申請者',
      );
      userRepository.addTestUser(sender);
      notificationRepository.addTestNotification(
        _friendRequest(
          id: 'deleted-receiver-request-id',
          sendUserId: sender.id,
          receiveUserId: 'deleted-receiver-id',
        ),
      );

      await useCase.execute('deleted-receiver-request-id');

      final notification = await notificationRepository
          .getNotification('deleted-receiver-request-id');
      final updatedSender = await userRepository.getUser(sender.id);

      expect(notification?.status, NotificationStatus.expired);
      expect(notification?.isRead, isTrue);
      expect(updatedSender?.friends, isNot(contains('deleted-receiver-id')));
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
