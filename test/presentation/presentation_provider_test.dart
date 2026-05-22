import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/interfaces/i_list_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_repository.dart';
import 'package:lakiite/presentation/my_page/my_page_view_model.dart'
    show timelineSchedulesProvider;
import 'package:lakiite/presentation/my_page/my_page_view_model.dart'
    as my_page;
import 'package:lakiite/presentation/calendar/calendar_providers.dart'
    as calendar;
import 'package:lakiite/presentation/list/list_providers.dart' as list_feature;
import 'package:lakiite/presentation/presentation_provider.dart'
    as presentation;
import 'package:lakiite/presentation/presentation_provider.dart';

import '../../mock/repositories/mock_auth_repository.dart';
import '../../mock/repositories/mock_user_repository.dart';

class _TrackingScheduleRepository implements IScheduleRepository {
  _TrackingScheduleRepository() {
    _controller
      ..onListen = () {
        listenCount++;
      }
      ..onCancel = () {
        cancelCount++;
      };
  }
  final _controller = StreamController<List<Schedule>>.broadcast();
  int cancelCount = 0;
  int listenCount = 0;

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) =>
      _controller.stream;

  @override
  Stream<List<Schedule>> watchUserSchedulesForMonth(
          String userId, DateTime displayMonth) =>
      _controller.stream;

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

class _TrackingListRepository implements IListRepository {
  _TrackingListRepository() {
    _listsController
      ..onListen = () {
        listsListenCount++;
      }
      ..onCancel = () {
        listsCancelCount++;
      };
    _listController
      ..onListen = () {
        listListenCount++;
      }
      ..onCancel = () {
        listCancelCount++;
      };
  }

  final _listsController = StreamController<List<UserList>>.broadcast();
  final _listController = StreamController<UserList?>.broadcast();
  int listCancelCount = 0;
  int listListenCount = 0;
  int listsCancelCount = 0;
  int listsListenCount = 0;

  @override
  Stream<List<UserList>> watchUserLists(String ownerId) =>
      _listsController.stream;

  @override
  Stream<UserList?> watchList(String listId) => _listController.stream;

  @override
  Future<void> addMember(String listId, String userId) =>
      Future.error(UnimplementedError());

  @override
  Future<UserList> createList({
    required String listName,
    required List<String> memberIds,
    required String ownerId,
    String? iconUrl,
    String? description,
  }) =>
      Future.error(UnimplementedError());

  @override
  Future<void> deleteList(String listId) => Future.error(UnimplementedError());

  @override
  Future<UserList?> getList(String listId) =>
      Future.error(UnimplementedError());

  @override
  Future<List<UserList>> getLists(String ownerId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> removeMember(String listId, String userId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> updateList(UserList list) => Future.error(UnimplementedError());

  void dispose() {
    _listsController.close();
    _listController.close();
  }
}

void main() {
  group('presentation providers', () {
    late ProviderContainer container;
    late MockAuthRepository mockAuthRepository;
    late _TrackingListRepository listRepository;
    late MockUserRepository mockUserRepository;
    late _TrackingScheduleRepository scheduleRepository;
    late UserModel testUser;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      listRepository = _TrackingListRepository();
      mockUserRepository = MockUserRepository();
      scheduleRepository = _TrackingScheduleRepository();
      testUser = UserModel.create(
        id: 'test-user-id',
        name: 'テストユーザー',
        displayName: 'テストユーザー',
      );

      mockAuthRepository.setUser(testUser);
      mockUserRepository.addTestUser(testUser);

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          listRepositoryProvider.overrideWithValue(listRepository),
          userRepositoryProvider.overrideWithValue(mockUserRepository),
          scheduleRepositoryProvider.overrideWithValue(scheduleRepository),
        ],
      );
    });

    tearDown(() {
      listRepository.dispose();
      scheduleRepository.dispose();
      mockAuthRepository.dispose();
      container.dispose();
    });

    test('userSchedulesStreamProvider はログアウト時に空配列へ切り替わる', () async {
      await container.read(authNotifierProvider.future);

      final subscription = container.listen(
        userSchedulesStreamProvider(testUser.id),
        (_, __) {},
        fireImmediately: true,
      );

      await mockAuthRepository.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(userSchedulesStreamProvider(testUser.id));
      expect(state.hasValue, isTrue);
      expect(state.value, isEmpty);

      subscription.close();
    });

    test('my_page は userSchedulesStreamProvider を再定義しない', () {
      expect(
        identical(
          my_page.userSchedulesStreamProvider,
          presentation.userSchedulesStreamProvider,
        ),
        isTrue,
      );
    });

    test('presentation_provider は selectedDateProvider を再定義しない', () {
      expect(
        identical(
          calendar.selectedDateProvider,
          presentation.selectedDateProvider,
        ),
        isTrue,
      );
    });

    test('timelineSchedulesProvider はログアウト時に空配列へ切り替わる', () async {
      await container.read(authNotifierProvider.future);

      final subscription = container.listen(
        timelineSchedulesProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await mockAuthRepository.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(timelineSchedulesProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, isEmpty);

      subscription.close();
    });

    test('presentation_provider は userListsStreamProvider を再定義しない', () {
      expect(
        identical(
          list_feature.userListsStreamProvider,
          presentation.userListsStreamProvider,
        ),
        isTrue,
      );
    });

    test('userListsStreamProvider はログアウト時に空配列へ切り替わる', () async {
      await container.read(authNotifierProvider.future);

      final subscription = container.listen(
        userListsStreamProvider,
        (_, __) {},
        fireImmediately: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(listRepository.listsListenCount, 1);

      await mockAuthRepository.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(userListsStreamProvider);
      expect(state.hasValue, isTrue);
      expect(state.value, isEmpty);
      expect(listRepository.listsCancelCount, 1);

      subscription.close();
    });

    test('listStreamProvider はログアウト時に null へ切り替わる', () async {
      await container.read(authNotifierProvider.future);

      final subscription = container.listen(
        listStreamProvider('test-list-id'),
        (_, __) {},
        fireImmediately: true,
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(listRepository.listListenCount, 1);

      await mockAuthRepository.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(listStreamProvider('test-list-id'));
      expect(state.hasValue, isTrue);
      expect(state.value, isNull);
      expect(listRepository.listCancelCount, 1);

      subscription.close();
    });
  });
}
