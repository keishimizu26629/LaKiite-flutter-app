import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/infrastructure/notification_navigation_service.dart';

void main() {
  group('NotificationNavigationService', () {
    testWidgets('通知一覧をNavigatorへpushできる', (tester) async {
      final service = NotificationNavigationService(
        notificationListBuilder: (_) => const Scaffold(
          body: Text('notification list'),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: service.navigatorKey,
          home: const Scaffold(body: Text('home')),
        ),
      );

      service.openNotificationList();
      await tester.pumpAndSettle();

      expect(find.text('notification list'), findsOneWidget);
    });

    testWidgets('Navigator準備前の通知タップは保留し、準備後に通知一覧を開く', (tester) async {
      final service = NotificationNavigationService(
        notificationListBuilder: (_) => const Scaffold(
          body: Text('notification list'),
        ),
      );

      service.openNotificationList();
      expect(service.hasPendingNotificationListOpen, isTrue);

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: service.navigatorKey,
          home: const Scaffold(body: Text('home')),
        ),
      );

      service.flushPendingNavigation();
      await tester.pumpAndSettle();

      expect(service.hasPendingNotificationListOpen, isFalse);
      expect(find.text('notification list'), findsOneWidget);
    });
  });
}
