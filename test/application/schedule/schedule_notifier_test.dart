import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/schedule/schedule_state.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/interfaces/i_schedule_repository.dart';
import 'package:lakiite/presentation/presentation_provider.dart';

import '../../../mock/repositories/mock_auth_repository.dart';
import '../../../mock/repositories/mock_user_repository.dart';

class _TrackingScheduleRepository implements IScheduleRepository {
  _TrackingScheduleRepository() {
    _controller.onCancel = () {
      cancelCount++;
    };
  }
  final _controller = StreamController<List<Schedule>>.broadcast();
  int cancelCount = 0;
  int watchUserSchedulesCallCount = 0;
  int watchUserSchedulesForMonthCallCount = 0;
  Object? monthError;

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) {
    watchUserSchedulesCallCount++;
    return _controller.stream;
  }

  @override
  Stream<List<Schedule>> watchUserSchedulesForMonth(
      String userId, DateTime displayMonth) {
    watchUserSchedulesForMonthCallCount++;
    if (monthError != null) {
      return Stream<List<Schedule>>.error(monthError!);
    }
    return _controller.stream;
  }

  @override
  Stream<List<Schedule>> watchListSchedules(String listId) =>
      _controller.stream;

  @override
  Stream<Schedule?> watchSchedule(String scheduleId) =>
      const Stream<Schedule?>.empty();

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

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('ScheduleNotifier', () {
    late ProviderContainer container;
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late _TrackingScheduleRepository scheduleRepository;
    ProviderSubscription<AsyncValue<ScheduleState>>? scheduleSubscription;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      scheduleRepository = _TrackingScheduleRepository();

      final testUser = UserModel.create(
        id: 'test-user-id',
        name: 'テストユーザー',
        displayName: 'テストユーザー',
      );
      mockUserRepository.addTestUser(testUser);
      mockAuthRepository.setUser(testUser);

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          userRepositoryProvider.overrideWithValue(mockUserRepository),
          scheduleRepositoryProvider.overrideWithValue(scheduleRepository),
        ],
      );

      scheduleSubscription = container.listen(
        scheduleNotifierProvider,
        (_, __) {},
        fireImmediately: true,
      );
    });

    tearDown(() {
      scheduleSubscription?.close();
      scheduleRepository.dispose();
      mockAuthRepository.dispose();
      container.dispose();
    });

    test('ログアウト時にスケジュール購読を解除して初期状態へ戻す', () async {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      expect(scheduleRepository.cancelCount, 0);

      await mockAuthRepository.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final scheduleState = container.read(scheduleNotifierProvider);
      expect(scheduleRepository.cancelCount, 1);
      expect(
        scheduleState.value,
        const ScheduleState.initial(),
      );
    });

    test('認証直後にログアウトした場合は遅延後の購読開始を行わない', () async {
      await mockAuthRepository.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 450));

      expect(scheduleRepository.watchUserSchedulesCallCount, 0);
      expect(container.read(scheduleNotifierProvider).value,
          const ScheduleState.initial());
    });

    test('月別購読の permission-denied は初期状態へ戻して終了する', () async {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      scheduleRepository.monthError = Exception(
        '[cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.',
      );

      container
          .read(scheduleNotifierProvider.notifier)
          .watchUserSchedulesForMonth('test-user-id', DateTime(2026, 3, 1));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(scheduleRepository.watchUserSchedulesForMonthCallCount,
          greaterThanOrEqualTo(1));
      expect(container.read(scheduleNotifierProvider).value,
          const ScheduleState.initial());
    });
  });
}
