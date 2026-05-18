import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lakiite/infrastructure/firebase/push_notification_sender.dart';

void main() {
  group('PushNotificationSender', () {
    test('宛先ユーザーの全FCMトークンへ通知を送る', () async {
      final postedPayloads = <Map<String, dynamic>>[];
      final sender = PushNotificationSender(
        cloudFunctionUrl: 'https://example.com/sendNotification',
        tokenResolver: (_) async => [
          'android-token',
          'ios-token',
          'android-token',
        ],
        httpClient: MockClient((request) async {
          postedPayloads.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response('{"success":true}', 200);
        }),
      );

      final result = await sender.sendFriendRequestNotification(
        toUserId: 'to-user',
        fromUserId: 'from-user',
        fromUserName: '送信者',
      );

      expect(result, isTrue);
      expect(postedPayloads, hasLength(2));
      expect(postedPayloads.map((payload) => payload['token']),
          ['android-token', 'ios-token']);
      final firstData = postedPayloads.first['data'] as Map<String, dynamic>;
      expect(firstData['type'], 'friend_request');
    });

    test('一部のトークン送信に失敗しても1件以上成功すれば成功扱いにする', () async {
      var requestCount = 0;
      final sender = PushNotificationSender(
        cloudFunctionUrl: 'https://example.com/sendNotification',
        tokenResolver: (_) async => ['android-token', 'ios-token'],
        httpClient: MockClient((request) async {
          requestCount++;
          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          if (payload['token'] == 'android-token') {
            return http.Response('server error', 500);
          }
          return http.Response('{"success":true}', 200);
        }),
      );

      final result = await sender.sendReactionNotification(
        toUserId: 'to-user',
        fromUserId: 'from-user',
        fromUserName: '送信者',
        scheduleId: 'schedule-id',
        interactionId: 'reaction-id',
      );

      expect(result, isTrue);
      expect(requestCount, 2);
    });

    test('FCMトークンがない場合は送信しない', () async {
      var didPost = false;
      final sender = PushNotificationSender(
        cloudFunctionUrl: 'https://example.com/sendNotification',
        tokenResolver: (_) async => [],
        httpClient: MockClient((request) async {
          didPost = true;
          return http.Response('{"success":true}', 200);
        }),
      );

      final result = await sender.sendGroupInvitationNotification(
        toUserId: 'to-user',
        fromUserId: 'from-user',
        fromUserName: '送信者',
        groupId: 'group-id',
        groupName: 'group',
      );

      expect(result, isFalse);
      expect(didPost, isFalse);
    });
  });
}
