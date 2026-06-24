import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/infrastructure/deep_link_navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DeepLinkNavigationService', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late DeepLinkNavigationService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      navigatorKey = GlobalKey<NavigatorState>();
      service = DeepLinkNavigationService(navigatorKey: navigatorKey);
      service.configureFriendSearchPageBuilder(
        (_, searchId) => Text('friend search: $searchId'),
      );
    });

    testWidgets('Navigator準備前のDeep Link遷移を保留して後で実行する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Text('home'),
        ),
      );

      await service.handleReceivedDeepLink(
        'lakiite://friend/search?searchId=ABCD1234',
      );

      expect(service.hasPendingFriendSearchOpen, isTrue);
      expect(find.text('friend search: ABCD1234'), findsNothing);

      await service.markNavigationReady();
      await tester.pumpAndSettle();

      expect(service.hasPendingFriendSearchOpen, isFalse);
      expect(find.text('friend search: ABCD1234'), findsOneWidget);
    });

    testWidgets('未ログイン中に受信したDeep Link遷移を永続化して認証後に実行する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Text('home'),
        ),
      );

      await service.handleReceivedDeepLink(
        'lakiitedev://friend/search?searchId=WXYZ5678',
      );

      final resumedService =
          DeepLinkNavigationService(navigatorKey: navigatorKey)
            ..configureFriendSearchPageBuilder(
              (_, searchId) => Text('friend search: $searchId'),
            );

      await resumedService.markNavigationReady();
      await tester.pumpAndSettle();

      expect(resumedService.hasPendingFriendSearchOpen, isFalse);
      expect(find.text('friend search: WXYZ5678'), findsOneWidget);

      final secondService =
          DeepLinkNavigationService(navigatorKey: navigatorKey)
            ..configureFriendSearchPageBuilder(
              (_, searchId) => Text('friend search again: $searchId'),
            );

      await secondService.markNavigationReady();
      await tester.pumpAndSettle();

      expect(find.text('friend search again: WXYZ5678'), findsNothing);
    });

    testWidgets('対応外Deep Linkでは遷移しない', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Text('home'),
        ),
      );
      await service.markNavigationReady();

      await service.handleReceivedDeepLink('lakiite://settings');
      await tester.pumpAndSettle();

      expect(service.hasPendingFriendSearchOpen, isFalse);
      expect(find.textContaining('friend search:'), findsNothing);
    });
  });
}
