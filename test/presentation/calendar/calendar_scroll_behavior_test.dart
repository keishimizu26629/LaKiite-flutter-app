import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/config/admob_config.dart';
import 'package:lakiite/config/app_config.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/interfaces/i_auth_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_repository.dart';
import 'package:lakiite/presentation/calendar/schedule_providers.dart';
import 'package:lakiite/presentation/calendar/widgets/calendar_page_view.dart';
import 'package:lakiite/presentation/home/home_page.dart';

import '../../mock/base_mock.dart';
import '../../mock/providers/test_providers.dart';
import '../../utils/test_utils.dart';

class _StableAuthRepository implements IAuthRepository {
  _StableAuthRepository(this._currentUser);

  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  @override
  Stream<UserModel?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }

  @override
  Future<UserModel?> signIn(String email, String password) async =>
      _currentUser;

  @override
  Future<UserModel?> signUp(String email, String password, String name) async =>
      _currentUser;

  @override
  Future<bool> deleteAccount() async => true;

  @override
  Future<bool> deleteAccountWithReauth(String password) async => true;

  @override
  Future<bool> reauthenticateWithPassword(String password) async => true;

  Future<void> dispose() => _controller.close();
}

class _StreamingScheduleRepository implements IScheduleRepository {
  final _controller = StreamController<List<Schedule>>.broadcast();
  List<Schedule>? _latestSchedules;
  int watchUserSchedulesForMonthCallCount = 0;

  void emit(List<Schedule> schedules) {
    _latestSchedules = schedules;
    _controller.add(schedules);
  }

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) async* {
    final latestSchedules = _latestSchedules;
    if (latestSchedules != null) {
      yield latestSchedules;
    }
    yield* _controller.stream;
  }

  @override
  Stream<List<Schedule>> watchUserSchedulesForMonth(
    String userId,
    DateTime displayMonth,
  ) async* {
    watchUserSchedulesForMonthCallCount++;
    final latestSchedules = _latestSchedules;
    if (latestSchedules != null) {
      yield latestSchedules;
    }
    yield* _controller.stream;
  }

  @override
  Stream<List<Schedule>> watchListSchedules(String listId) =>
      const Stream.empty();

  @override
  Stream<Schedule?> watchSchedule(String scheduleId) => const Stream.empty();

  @override
  Future<Schedule> createSchedule(Schedule schedule) =>
      Future.error(UnimplementedError());

  @override
  Future<void> deleteSchedule(String scheduleId) =>
      Future.error(UnimplementedError());

  @override
  Future<List<Schedule>> getListSchedules(String listId) =>
      Future.error(UnimplementedError());

  @override
  Future<List<Schedule>> getUserSchedules(String userId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> updateSchedule(Schedule schedule) =>
      Future.error(UnimplementedError());

  Future<void> dispose() => _controller.close();
}

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

    testWidgets('カレンダーはスライド中の予定更新を表示へ反映せず完了後に反映する', (tester) async {
      final scheduleRepository = _StreamingScheduleRepository();
      addTearDown(scheduleRepository.dispose);
      final userRepository = TestProviders.mockUserRepository;
      final testUser = BaseMock.createTestUser();
      final authRepository = _StableAuthRepository(testUser);
      addTearDown(authRepository.dispose);
      userRepository.addTestUser(testUser);

      final now = DateTime.now();
      final initialSchedule = BaseMock.createTestSchedule(
        id: 'schedule-deferred-ui',
        title: 'スライド前予定',
        startDateTime: DateTime(now.year, now.month, 15, 10),
        endDateTime: DateTime(now.year, now.month, 15, 11),
      );
      final updatedSchedule = initialSchedule.copyWith(
        title: 'スライド後予定',
        startDateTime: DateTime(now.year, now.month, 16, 10),
        endDateTime: DateTime(now.year, now.month, 16, 11),
      );
      scheduleRepository.emit([initialSchedule]);

      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepository),
            userRepositoryProvider.overrideWithValue(userRepository),
            scheduleRepositoryProvider.overrideWithValue(scheduleRepository),
            calendarOptimizationProvider.overrideWith((ref) => false),
          ],
          child: const Scaffold(
            body: CalendarPageView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 150));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarPageView)),
      );
      container.read(calendarOptimizationProvider.notifier).state = false;
      await tester.pump();

      expect(scheduleRepository.watchUserSchedulesForMonthCallCount,
          greaterThan(0));
      final schedulesState = container.read(
        calendarMonthSchedulesProvider((
          userId: testUser.id,
          displayMonth: DateTime(now.year, now.month),
        )),
      );
      expect(schedulesState.valueOrNull, isNotEmpty);
      expect(_textWidget('スライド前予定'), findsOneWidget);
      expect(_textWidget('スライド後予定'), findsNothing);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump();

      scheduleRepository.emit([updatedSchedule]);
      await tester.pump();

      expect(_textWidget('スライド後予定'), findsNothing);
      final oldLightweightCell = tester.widget<LightweightDateCell>(
        find.byKey(ValueKey(_dateLiteKey(DateTime(now.year, now.month, 15)))),
      );
      final newLightweightCell = tester.widget<LightweightDateCell>(
        find.byKey(ValueKey(_dateLiteKey(DateTime(now.year, now.month, 16)))),
      );
      expect(oldLightweightCell.hasSchedules, isTrue);
      expect(newLightweightCell.hasSchedules, isFalse);

      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 550));

      expect(_textWidget('スライド前予定'), findsNothing);
      expect(_textWidget('スライド後予定'), findsOneWidget);
    });

    testWidgets('カレンダーはスライド終了後約200msで予定タイトル表示を復帰する', (tester) async {
      final scheduleRepository = _StreamingScheduleRepository();
      addTearDown(scheduleRepository.dispose);
      final userRepository = TestProviders.mockUserRepository;
      final testUser = BaseMock.createTestUser();
      final authRepository = _StableAuthRepository(testUser);
      addTearDown(authRepository.dispose);
      userRepository.addTestUser(testUser);

      final now = DateTime.now();
      final initialSchedule = BaseMock.createTestSchedule(
        id: 'schedule-fast-restore',
        title: '高速復帰前',
        startDateTime: DateTime(now.year, now.month, 15, 10),
        endDateTime: DateTime(now.year, now.month, 15, 11),
      );
      final updatedSchedule = initialSchedule.copyWith(title: '高速復帰後');
      scheduleRepository.emit([initialSchedule]);

      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepository),
            userRepositoryProvider.overrideWithValue(userRepository),
            scheduleRepositoryProvider.overrideWithValue(scheduleRepository),
            calendarOptimizationProvider.overrideWith((ref) => false),
          ],
          child: const Scaffold(
            body: CalendarPageView(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarPageView)),
      );
      container.read(calendarOptimizationProvider.notifier).state = false;
      await tester.pump();

      expect(_textWidget('高速復帰前'), findsOneWidget);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PageView)),
      );
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump();

      scheduleRepository.emit([updatedSchedule]);
      await tester.pump();
      expect(_textWidget('高速復帰後'), findsNothing);

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 250));

      expect(_textWidget('高速復帰前'), findsNothing);
      expect(_textWidget('高速復帰後'), findsOneWidget);
    });

    testWidgets('月次ページは最適化中のStream更新で表示用予定位置を動かさない', (tester) async {
      final scheduleRepository = _StreamingScheduleRepository();
      addTearDown(scheduleRepository.dispose);
      final userRepository = TestProviders.mockUserRepository;
      final testUser = BaseMock.createTestUser();
      final authRepository = _StableAuthRepository(testUser);
      addTearDown(authRepository.dispose);
      userRepository.addTestUser(testUser);

      final now = DateTime.now();
      final visibleMonth = DateTime(now.year, now.month);
      final initialSchedule = BaseMock.createTestSchedule(
        id: 'schedule-page-content-deferred-ui',
        title: 'ページ単体スライド前',
        startDateTime: DateTime(now.year, now.month, 15, 10),
        endDateTime: DateTime(now.year, now.month, 15, 11),
      );
      final updatedSchedule = initialSchedule.copyWith(
        title: 'ページ単体スライド後',
        startDateTime: DateTime(now.year, now.month, 16, 10),
        endDateTime: DateTime(now.year, now.month, 16, 11),
      );
      scheduleRepository.emit([initialSchedule]);

      await tester.pumpWidget(
        TestUtils.createTestApp(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepository),
            userRepositoryProvider.overrideWithValue(userRepository),
            scheduleRepositoryProvider.overrideWithValue(scheduleRepository),
            calendarOptimizationProvider.overrideWith((ref) => true),
          ],
          child: Scaffold(
            body: CalendarPageContent(
              visiblePageDate: visibleMonth,
              monthKey: getMonthKey(visibleMonth),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      scheduleRepository.emit([updatedSchedule]);
      await tester.pump();

      final oldLightweightCell = tester.widget<LightweightDateCell>(
        find.byKey(ValueKey(_dateLiteKey(DateTime(now.year, now.month, 15)))),
      );
      final newLightweightCell = tester.widget<LightweightDateCell>(
        find.byKey(ValueKey(_dateLiteKey(DateTime(now.year, now.month, 16)))),
      );
      expect(oldLightweightCell.hasSchedules, isTrue);
      expect(newLightweightCell.hasSchedules, isFalse);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(CalendarPageContent)),
      );
      container.read(calendarOptimizationProvider.notifier).state = false;
      await tester.pump();

      expect(_textWidget('ページ単体スライド前'), findsNothing);
      expect(_textWidget('ページ単体スライド後'), findsOneWidget);
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

Finder _textWidget(String text) {
  return find.byWidgetPredicate(
    (widget) => widget is Text && widget.data == text,
  );
}

String _dateLiteKey(DateTime date) {
  final dateString =
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  return 'date_lite_$dateString';
}
