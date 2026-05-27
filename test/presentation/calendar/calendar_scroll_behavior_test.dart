import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lakiite/config/admob_config.dart';
import 'package:lakiite/config/app_config.dart';
import 'package:lakiite/presentation/calendar/widgets/calendar_page_view.dart';
import 'package:lakiite/presentation/home/home_page.dart';

import '../../mock/providers/test_providers.dart';
import '../../utils/test_utils.dart';

void main() {
  group('Calendar scroll behavior', () {
    setUpAll(() async {
      AppConfig.initialize(Environment.development);
      AdMobConfig.initialize(forceTestMode: true);
      await initializeDateFormatting('ja_JP', null);
    });

    setUp(() {
      TestProviders.reset();
    });

    tearDown(() {
      TestProviders.reset();
    });

    testWidgets('ホームのタブ切り替えは横スワイプを受け付けない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: HomeTabBarView(
              children: [
                Text('カレンダー'),
                Text('タイムライン'),
              ],
            ),
          ),
        ),
      );

      final tabBarView = tester.widget<TabBarView>(find.byType(TabBarView));
      expect(tabBarView.physics, isA<NeverScrollableScrollPhysics>());
    });

    testWidgets('カレンダー月送りは標準のページスクロール挙動を使う', (tester) async {
      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: TestProviders.authenticated,
          child: const Scaffold(
            body: CalendarPageView(),
          ),
        ),
      );
      await tester.pump();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.physics, isA<PageScrollPhysics>());
    });
  });
}
