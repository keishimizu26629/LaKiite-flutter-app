import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/schedule/schedule_notifier.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/service/schedule_manager.dart';

import '../../mock/analytics/recording_growth_analytics.dart';

void main() {
  group('ScheduleNotifier createSchedule growth analytics', () {
    late RecordingGrowthAnalytics analytics;
    late _CreateScheduleManager scheduleManager;
    late ProviderContainer container;
    late ProviderSubscription subscription;

    setUp(() {
      final user = UserModel.create(
        id: 'owner-id',
        name: 'owner',
        displayName: 'Owner',
      );
      analytics = RecordingGrowthAnalytics();
      scheduleManager = _CreateScheduleManager();
      container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
            () => _StubAuthNotifier(AuthState.authenticated(user)),
          ),
          scheduleManagerProvider.overrideWithValue(scheduleManager),
          growthAnalyticsProvider.overrideWithValue(analytics),
        ],
      );
      subscription = container.listen(
        scheduleNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );
    });

    tearDown(() {
      subscription.close();
      container.dispose();
    });

    test('保存済みScheduleから作成者を除くunique共有数を1回記録する', () async {
      scheduleManager.createdVisibleTo = [
        'owner-id',
        'friend-a',
        'friend-a',
        'friend-b',
        'friend-c',
      ];

      await container.read(scheduleNotifierProvider.notifier).createSchedule(
        title: 'title',
        description: 'description',
        startDateTime: DateTime(2026, 9, 6, 10),
        endDateTime: DateTime(2026, 9, 6, 11),
        isAllDay: true,
        ownerId: 'owner-id',
        sharedLists: const ['list-a', 'list-b'],
        visibleTo: const [],
      );

      final call = analytics.scheduleCreatedCalls.single;
      expect(call.recipientCount, 3);
      expect(call.sharedListCount, 2);
      expect(call.isAllDay, isTrue);
    });

    test('Manager保存失敗時は記録しない', () async {
      scheduleManager.shouldFail = true;

      await container.read(scheduleNotifierProvider.notifier).createSchedule(
        title: 'title',
        description: 'description',
        startDateTime: DateTime(2026, 9, 6, 10),
        endDateTime: DateTime(2026, 9, 6, 11),
        ownerId: 'owner-id',
        sharedLists: const [],
        visibleTo: const [],
      );

      expect(analytics.scheduleCreatedCalls, isEmpty);
      expect(container.read(scheduleNotifierProvider).hasError, isTrue);
    });
  });
}

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._state);

  final AuthState _state;

  @override
  FutureOr<AuthState> build() => _state;
}

class _CreateScheduleManager implements IScheduleManager {
  List<String> createdVisibleTo = const [];
  bool shouldFail = false;

  @override
  Future<Schedule> createSchedule(Schedule schedule) async {
    if (shouldFail) throw StateError('save failed');
    return schedule.copyWith(
      id: 'created-schedule-id',
      visibleTo: createdVisibleTo,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
