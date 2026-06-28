import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/infrastructure/airbridge_deep_link_service.dart';
import 'package:lakiite/infrastructure/deep_link_navigation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AirbridgeDeepLinkService', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late DeepLinkNavigationService navigationService;
    late MethodChannel nativeDeepLinkChannel;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      navigatorKey = GlobalKey<NavigatorState>();
      navigationService = DeepLinkNavigationService(navigatorKey: navigatorKey)
        ..configureFriendSearchPageBuilder(
          (_, searchId) => Text('friend search: $searchId'),
        );
      nativeDeepLinkChannel = const MethodChannel('test_lakiite/deep_link');
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativeDeepLinkChannel, null);
    });

    testWidgets('Native初期Deep Linkを友達検索遷移へ流す', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativeDeepLinkChannel, (call) async {
        if (call.method == 'getInitialDeepLink') {
          return 'https://lakiitedev.airbridge.io/friend/search?searchId=Pj5I7M58';
        }
        return null;
      });

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Text('home'),
        ),
      );

      AirbridgeDeepLinkService(
        navigationService: navigationService,
        nativeDeepLinkChannel: nativeDeepLinkChannel,
        enableAirbridgeRuntime: false,
      ).start();
      await tester.pump();

      await navigationService.markNavigationReady();
      await tester.pumpAndSettle();

      expect(find.text('friend search: Pj5I7M58'), findsOneWidget);
    });

    testWidgets('Nativeから通知されたDeep Linkを友達検索遷移へ流す', (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(nativeDeepLinkChannel, (call) async {
        if (call.method == 'getInitialDeepLink') {
          return null;
        }
        return null;
      });

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Text('home'),
        ),
      );

      AirbridgeDeepLinkService(
        navigationService: navigationService,
        nativeDeepLinkChannel: nativeDeepLinkChannel,
        enableAirbridgeRuntime: false,
      ).start();
      await tester.pump();

      final encodedCall = nativeDeepLinkChannel.codec.encodeMethodCall(
        const MethodCall(
          'onDeepLink',
          'lakiitedev://friend/search?searchId=Pj5I7M58',
        ),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        nativeDeepLinkChannel.name,
        encodedCall,
        (ByteData? data) {},
      );

      await navigationService.markNavigationReady();
      await tester.pumpAndSettle();

      expect(find.text('friend search: Pj5I7M58'), findsOneWidget);
    });
  });
}
