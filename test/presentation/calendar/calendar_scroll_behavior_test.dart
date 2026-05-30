import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    testWidgets('カレンダー月送りは短いドラッグ向けのページスクロール挙動を使う', (tester) async {
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
      expect(pageView.physics, isA<CalendarPageScrollPhysics>());
      expect(pageView.pageSnapping, isFalse);
    });

    testWidgets('カレンダーは表示月と前後月の3ページだけを固定作成する', (tester) async {
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
      final pageController = pageView.controller as PageController;

      expect(pageController.initialPage, 1);
      expect(pageView.allowImplicitScrolling, isTrue);
      expect(pageView.childrenDelegate, isA<SliverChildListDelegate>());
      expect(
        find.byType(CalendarPageContent, skipOffstage: false),
        findsNWidgets(3),
      );
    });

    testWidgets('カレンダーは短めの低速スワイプでも前後の月へ移動する', (tester) async {
      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: TestProviders.authenticated,
          child: const Scaffold(
            body: CalendarPageView(),
          ),
        ),
      );
      await tester.pump();

      final initialMonth = _visibleMonthLabel(tester);

      await tester.timedDrag(
        find.byType(PageView),
        const Offset(-80, 0),
        const Duration(milliseconds: 800),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 550));

      expect(_visibleMonthLabel(tester), isNot(initialMonth));

      await tester.timedDrag(
        find.byType(PageView),
        const Offset(80, 0),
        const Duration(milliseconds: 800),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 550));

      expect(_visibleMonthLabel(tester), initialMonth);
    });

    testWidgets('カレンダーはドラッグ中に表示月の状態更新を確定しない', (tester) async {
      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: TestProviders.authenticated,
          child: const Scaffold(
            body: CalendarPageView(),
          ),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarPageView)),
      );
      final initialIndex = container.read(calendarCurrentIndexProvider);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump();

      expect(container.read(calendarCurrentIndexProvider), initialIndex);

      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 550));
    });

    testWidgets('カレンダーは連続スクロール中に前回の遅延処理を実行しない', (tester) async {
      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: TestProviders.authenticated,
          child: const Scaffold(
            body: CalendarPageView(),
          ),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarPageView)),
      );

      final firstGesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await firstGesture.moveBy(const Offset(-80, 0));
      await tester.pump();
      await firstGesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      final secondGesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await secondGesture.moveBy(const Offset(-80, 0));
      await tester.pump(const Duration(milliseconds: 250));

      expect(container.read(calendarOptimizationProvider), isTrue);

      await secondGesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 550));
    });

    testWidgets('カレンダーは連続スクロール中に中間月のキャッシュ範囲を確定しない', (tester) async {
      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: TestProviders.authenticated,
          child: const Scaffold(
            body: CalendarPageView(),
          ),
        ),
      );
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarPageView)),
      );
      final initialActiveIndices = container.read(activeMonthIndicesProvider);
      final initialRenderedMonths = container.read(renderedMonthsProvider);

      final firstGesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await firstGesture.moveBy(const Offset(-80, 0));
      await tester.pump();
      await firstGesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      final secondGesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await secondGesture.moveBy(const Offset(-80, 0));
      await tester.pump(const Duration(milliseconds: 250));

      expect(container.read(activeMonthIndicesProvider), initialActiveIndices);
      expect(container.read(renderedMonthsProvider), initialRenderedMonths);

      await secondGesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 550));
    });
  });
}

String _visibleMonthLabel(WidgetTester tester) {
  final monthLabels = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .where((text) => RegExp(r'^\d{4}年\d{1,2}月$').hasMatch(text))
      .toList();

  expect(monthLabels, isNotEmpty);
  return monthLabels.first;
}
