import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/interfaces/i_growth_analytics.dart';
import 'package:lakiite/infrastructure/deep_link_invite_preferences.dart';
import 'package:lakiite/infrastructure/deep_link_navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mock/analytics/recording_growth_analytics.dart';

class _FailingDeepLinkInvitePreferences extends DeepLinkInvitePreferences {
  const _FailingDeepLinkInvitePreferences();

  @override
  Future<void> savePendingFriendSearchId(String searchId) async {
    throw StateError('preference save failed');
  }
}

void main() {
  group('DeepLinkNavigationService', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late DeepLinkNavigationService service;
    late RecordingGrowthAnalytics analytics;
    late DateTime now;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      navigatorKey = GlobalKey<NavigatorState>();
      analytics = RecordingGrowthAnalytics();
      now = DateTime.utc(2026, 9, 6);
      service = DeepLinkNavigationService(
        navigatorKey: navigatorKey,
        growthAnalytics: analytics,
        now: () => now,
      );
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
      expect(analytics.inviteOpenTransports, isEmpty);
    });

    test('pending保存成功後にlink transportだけを記録する', () async {
      await service.handleReceivedDeepLink(
        'https://lakiite.airbridge.io/friend/search?searchId=ABCD1234',
      );
      await service.handleReceivedDeepLink(
        'https://invite.lakiite.inoworl.com/friend/search?searchId=EFGH5678',
      );
      await service.handleReceivedDeepLink(
        'lakiite://friend/search?searchId=IJKL9012',
      );

      expect(analytics.inviteOpenTransports, [
        FriendInviteLinkTransport.airbridge,
        FriendInviteLinkTransport.universalLink,
        FriendInviteLinkTransport.customScheme,
      ]);
    });

    test('pending保存失敗時はinvite openを記録しない', () async {
      service = DeepLinkNavigationService(
        navigatorKey: navigatorKey,
        deepLinkInvitePreferences: const _FailingDeepLinkInvitePreferences(),
        growthAnalytics: analytics,
      );

      await expectLater(
        service.handleReceivedDeepLink(
          'lakiite://friend/search?searchId=ABCD1234',
        ),
        throwsStateError,
      );

      expect(analytics.inviteOpenTransports, isEmpty);
    });

    testWidgets('GoRouter用の遷移が設定されている場合はNavigator直pushではなく委譲する',
        (tester) async {
      final navigatedSearchIds = <String>[];
      service = DeepLinkNavigationService(
        navigatorKey: navigatorKey,
        friendSearchNavigator: (searchId) async {
          navigatedSearchIds.add(searchId);
        },
        friendSearchPageBuilder: (_, searchId) =>
            Text('friend search fallback: $searchId'),
      );

      await service.markNavigationReady();

      await service.handleReceivedDeepLink(
        'lakiite://friend/search?searchId=ABCD1234',
      );
      await tester.pumpAndSettle();

      expect(navigatedSearchIds, ['ABCD1234']);
      expect(find.text('friend search fallback: ABCD1234'), findsNothing);
      expect(service.hasPendingFriendSearchOpen, isFalse);
    });

    testWidgets('同じ検索IDのDeep Linkを表示中に重複受信しても二重遷移しない', (tester) async {
      final openedSearchIds = <String>[];
      service.configureFriendSearchPageBuilder(
        (_, searchId) {
          openedSearchIds.add(searchId);
          return Text('friend search: $searchId');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Text('home'),
        ),
      );
      await service.markNavigationReady();

      await service.handleReceivedDeepLink(
        'https://lakiitedev.airbridge.io/friend/search?searchId=Pj5I7M58',
      );
      await service.handleReceivedDeepLink(
        'lakiitedev://friend/search?searchId=Pj5I7M58',
      );
      await tester.pumpAndSettle();

      expect(openedSearchIds, ['Pj5I7M58']);
      expect(find.text('friend search: Pj5I7M58'), findsOneWidget);
      expect(
        analytics.inviteOpenTransports,
        [FriendInviteLinkTransport.airbridge],
      );
    });

    test('同じ招待でも10秒を超えた後は再度記録する', () async {
      const deepLink = 'lakiite://friend/search?searchId=ABCD1234';

      await service.handleReceivedDeepLink(deepLink);
      now = now.add(const Duration(seconds: 11));
      await service.handleReceivedDeepLink(deepLink);

      expect(analytics.inviteOpenTransports, [
        FriendInviteLinkTransport.customScheme,
        FriendInviteLinkTransport.customScheme,
      ]);
    });

    test('同じ招待はちょうど10秒後でも重複記録しない', () async {
      const deepLink = 'lakiite://friend/search?searchId=ABCD1234';

      await service.handleReceivedDeepLink(deepLink);
      now = now.add(const Duration(seconds: 10));
      await service.handleReceivedDeepLink(deepLink);

      expect(
        analytics.inviteOpenTransports,
        [FriendInviteLinkTransport.customScheme],
      );
    });

    testWidgets('別の検索IDのDeep Linkは友達検索画面を表示中でも遷移する', (tester) async {
      final openedSearchIds = <String>[];
      service.configureFriendSearchPageBuilder(
        (_, searchId) {
          openedSearchIds.add(searchId);
          return Text('friend search: $searchId');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Text('home'),
        ),
      );
      await service.markNavigationReady();

      await service.handleReceivedDeepLink(
        'https://lakiitedev.airbridge.io/friend/search?searchId=Pj5I7M58',
      );
      await service.handleReceivedDeepLink(
        'lakiitedev://friend/search?searchId=ABCD1234',
      );
      await tester.pumpAndSettle();

      expect(openedSearchIds, ['Pj5I7M58', 'ABCD1234']);
      expect(find.text('friend search: ABCD1234'), findsOneWidget);
    });

    testWidgets('同じ検索IDのDeep Linkでも友達検索画面を閉じた後は再度遷移できる', (tester) async {
      final openedSearchIds = <String>[];
      service.configureFriendSearchPageBuilder(
        (_, searchId) {
          openedSearchIds.add(searchId);
          return Text('friend search: $searchId');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Text('home'),
        ),
      );
      await service.markNavigationReady();

      await service.handleReceivedDeepLink(
        'https://lakiitedev.airbridge.io/friend/search?searchId=Pj5I7M58',
      );
      await tester.pumpAndSettle();

      expect(find.text('friend search: Pj5I7M58'), findsOneWidget);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      await service.handleReceivedDeepLink(
        'lakiitedev://friend/search?searchId=Pj5I7M58',
      );
      await tester.pumpAndSettle();

      expect(openedSearchIds, ['Pj5I7M58', 'Pj5I7M58']);
      expect(find.text('friend search: Pj5I7M58'), findsOneWidget);
    });
  });
}
