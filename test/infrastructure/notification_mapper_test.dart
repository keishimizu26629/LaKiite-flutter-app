import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/notification.dart';
import 'package:lakiite/infrastructure/mapper/notification_mapper.dart';

void main() {
  group('NotificationMapper', () {
    test('Firestore dataからNotificationを復元する', () {
      final createdAt = DateTime(2026);
      final updatedAt = DateTime(2026, 1, 2);

      final notification = NotificationMapper.fromFirestore(
        id: 'notification-1',
        data: {
          'type': 'reaction',
          'sendUserId': 'sender-1',
          'receiveUserId': 'receiver-1',
          'sendUserDisplayName': 'Sender',
          'status': 'accepted',
          'createdAt': Timestamp.fromDate(createdAt),
          'updatedAt': Timestamp.fromDate(updatedAt),
          'isRead': true,
          'relatedItemId': 'schedule-1',
          'interactionId': 'reaction-1',
        },
      );

      expect(notification.id, 'notification-1');
      expect(notification.type, NotificationType.reaction);
      expect(notification.status, NotificationStatus.accepted);
      expect(notification.createdAt, createdAt);
      expect(notification.updatedAt, updatedAt);
      expect(notification.relatedItemId, 'schedule-1');
      expect(notification.interactionId, 'reaction-1');
    });

    test('NotificationをFirestore保存用dataへ変換する', () {
      final notification = Notification.createGroupInvitation(
        fromUserId: 'sender-1',
        toUserId: 'receiver-1',
        groupId: 'group-1',
        fromUserDisplayName: 'Sender',
        toUserDisplayName: 'Receiver',
      );

      final data = NotificationMapper.toFirestore(notification);

      expect(data, isNot(contains('id')));
      expect(data['type'], 'groupInvitation');
      expect(data['status'], 'pending');
      expect(data['sendUserId'], 'sender-1');
      expect(data['receiveUserId'], 'receiver-1');
      expect(data['groupId'], 'group-1');
      expect(data['createdAt'], isA<FieldValue>());
      expect(data['updatedAt'], isA<FieldValue>());
    });
  });
}
