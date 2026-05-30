import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/interfaces/i_auth_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_repository.dart';
import 'package:lakiite/presentation/calendar/schedule_providers.dart';

import '../../mock/repository/mock_user_repository.dart';

class _FakeAuthRepository implements IAuthRepository {
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Stream<UserModel?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<void> signOut() async {
    setCurrentUser(null);
  }

  @override
  Future<UserModel?> signIn(String email, String password) {
    throw UnimplementedError();
  }

  @override
  Future<UserModel?> signUp(String email, String password, String name) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteAccount() {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteAccountWithReauth(String password) {
    throw UnimplementedError();
  }

  @override
  Future<bool> reauthenticateWithPassword(String password) {
    throw UnimplementedError();
  }

  void dispose() {
    _controller.close();
  }
}

class _TrackingScheduleRepository implements IScheduleRepository {
  _TrackingScheduleRepository() {
    _allController.onCancel = () {
      watchUserSchedulesCancelCount++;
    };
    _monthController.onCancel = () {
      watchUserSchedulesForMonthCancelCount++;
    };
    _scheduleController.onCancel = () {
      watchScheduleCancelCount++;
    };
  }

  final _monthController = StreamController<List<Schedule>>.broadcast();
  final _allController = StreamController<List<Schedule>>.broadcast();
  final _scheduleController = StreamController<Schedule?>.broadcast();

  int watchUserSchedulesCallCount = 0;
  int watchUserSchedulesForMonthCallCount = 0;
  int watchScheduleCallCount = 0;
  int watchUserSchedulesCancelCount = 0;
  int watchUserSchedulesForMonthCancelCount = 0;
  int watchScheduleCancelCount = 0;
  DateTime? lastDisplayMonth;

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) {
    watchUserSchedulesCallCount++;
    return _allController.stream;
  }

  @override
  Stream<List<Schedule>> watchUserSchedulesForMonth(
    String userId,
    DateTime displayMonth,
  ) {
    watchUserSchedulesForMonthCallCount++;
    lastDisplayMonth = displayMonth;
    return _monthController.stream;
  }

  @override
  Stream<List<Schedule>> watchListSchedules(String listId) =>
      const Stream.empty();

  @override
  Stream<Schedule?> watchSchedule(String scheduleId) {
    watchScheduleCallCount++;
    return _scheduleController.stream;
  }

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
    _monthController.close();
    _allController.close();
    _scheduleController.close();
  }
}

void main() {
  group('calendarMonthSchedulesProvider', () {
    late ProviderContainer container;
    late _FakeAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;
    late _TrackingScheduleRepository scheduleRepository;
    late UserModel testUser;

    setUp(() {
      mockAuthRepository = _FakeAuthRepository();
      mockUserRepository = MockUserRepository();
      scheduleRepository = _TrackingScheduleRepository();
      testUser = UserModel.create(
        id: 'test-user-id',
        name: 'テストユーザー',
        displayName: 'テストユーザー',
      );

      mockUserRepository.addTestUser(testUser);

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          userRepositoryProvider.overrideWithValue(mockUserRepository),
          scheduleRepositoryProvider.overrideWithValue(scheduleRepository),
        ],
      );
    });

    tearDown(() {
      scheduleRepository.dispose();
      mockAuthRepository.dispose();
      container.dispose();
    });

    test('カレンダー専用の月別購読だけを開始し、全体購読を使わない', () async {
      final authSubscription = _listenAuthenticatedAuthState(
        container,
        mockAuthRepository,
        testUser,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final subscription = container.listen(
        calendarMonthSchedulesProvider((
          userId: testUser.id,
          displayMonth: DateTime(2026, 3, 20),
        )),
        (_, __) {},
        fireImmediately: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(scheduleRepository.watchUserSchedulesForMonthCallCount, 1);
      expect(scheduleRepository.watchUserSchedulesCallCount, 0);
      expect(scheduleRepository.lastDisplayMonth, DateTime(2026, 3, 1));

      subscription.close();
      authSubscription.close();
    });

    test('ログアウト時はrepositoryを購読せず空配列を返す', () async {
      final authSubscription = _listenAuthenticatedAuthState(
        container,
        mockAuthRepository,
        testUser,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await mockAuthRepository.signOut();

      final provider = calendarMonthSchedulesProvider((
        userId: testUser.id,
        displayMonth: DateTime(2026, 3, 20),
      ));
      final subscription = container.listen(
        provider,
        (_, __) {},
        fireImmediately: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(provider);

      expect(state.hasValue, isTrue);
      expect(state.value, isEmpty);
      expect(scheduleRepository.watchUserSchedulesForMonthCallCount, 0);
      expect(scheduleRepository.watchUserSchedulesCallCount, 0);

      subscription.close();
      authSubscription.close();
    });

    test('userSchedulesStreamProvider は購読終了時にrepository購読を破棄する', () async {
      final authSubscription = _listenAuthenticatedAuthState(
        container,
        mockAuthRepository,
        testUser,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final provider = userSchedulesStreamProvider(testUser.id);
      final subscription = container.listen(
        provider,
        (_, __) {},
        fireImmediately: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(scheduleRepository.watchUserSchedulesCallCount, 1);

      subscription.close();
      await container.pump();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.exists(provider), isFalse);
      authSubscription.close();
    });

    test('calendarMonthSchedulesProvider は購読終了時にrepository購読を破棄する', () async {
      final authSubscription = _listenAuthenticatedAuthState(
        container,
        mockAuthRepository,
        testUser,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final provider = calendarMonthSchedulesProvider((
        userId: testUser.id,
        displayMonth: DateTime(2026, 3, 20),
      ));
      final subscription = container.listen(
        provider,
        (_, __) {},
        fireImmediately: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(scheduleRepository.watchUserSchedulesForMonthCallCount, 1);

      subscription.close();
      await container.pump();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.exists(provider), isFalse);
      authSubscription.close();
    });

    test('scheduleStreamProvider は予定詳細の単体購読をautoDisposeする', () async {
      final authSubscription = _listenAuthenticatedAuthState(
        container,
        mockAuthRepository,
        testUser,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final provider = scheduleStreamProvider('schedule-1');
      final subscription = container.listen(
        provider,
        (_, __) {},
        fireImmediately: true,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(scheduleRepository.watchScheduleCallCount, 1);

      subscription.close();
      await container.pump();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.exists(provider), isFalse);
      authSubscription.close();
    });
  });
}

ProviderSubscription<AsyncValue<AuthState>> _listenAuthenticatedAuthState(
  ProviderContainer container,
  _FakeAuthRepository authRepository,
  UserModel user,
) {
  final subscription = container.listen(
    authNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  authRepository.setCurrentUser(user);
  return subscription;
}
