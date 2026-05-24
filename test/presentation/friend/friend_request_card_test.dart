import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/notification.dart' as domain;
import 'package:lakiite/presentation/friend/friend_request_list_page.dart';

void main() {
  group('FriendRequestCard', () {
    testWidgets('期限切れの友達申請は退会済みで承認不可として表示する', (tester) async {
      final request = domain.Notification(
        id: 'request-id',
        type: domain.NotificationType.friend,
        sendUserId: 'deleted-sender-id',
        receiveUserId: 'receiver-id',
        sendUserDisplayName: '申請者',
        receiveUserDisplayName: '受信者',
        status: domain.NotificationStatus.expired,
        createdAt: DateTime(2026, 5, 22),
        updatedAt: DateTime(2026, 5, 22),
        isRead: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FriendRequestCard(
              request: request,
              onAccept: () async {},
              onReject: () {},
            ),
          ),
        ),
      );

      expect(find.text('退会済みユーザーからの友達申請です'), findsOneWidget);
      expect(find.text('このユーザーは退会済みのため承認できません'), findsOneWidget);
      expect(find.text('拒否済み'), findsNothing);
      expect(find.text('承認'), findsNothing);
      expect(find.text('拒否'), findsNothing);
    });
  });
}
