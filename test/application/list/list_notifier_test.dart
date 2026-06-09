import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/list/list_notifier.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/interfaces/i_list_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_access_grant_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_repository.dart';

import '../../../mock/repositories/mock_auth_repository.dart';
import '../../../mock/repositories/mock_user_repository.dart';

class _TrackingListRepository implements IListRepository {
  _TrackingListRepository() {
    _listsController.onCancel = () {
      cancelCount++;
    };
  }

  final _listsController = StreamController<List<UserList>>.broadcast();
  int cancelCount = 0;
  final addedMembers = <({String listId, String userId})>[];

  @override
  Stream<List<UserList>> watchUserLists(String ownerId) =>
      _listsController.stream;

  @override
  Stream<UserList?> watchList(String listId) => const Stream<UserList?>.empty();

  @override
  Future<void> addMember(String listId, String userId) async {
    addedMembers.add((listId: listId, userId: userId));
  }

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
  }
}

class _TrackingScheduleAccessGrantRepository
    implements IScheduleRepository, IScheduleAccessGrantRepository {
  final grantRequests = <({String listId, String userId})>[];

  @override
  Future<void> grantListSchedulesAccessToUser({
    required String listId,
    required String userId,
  }) async {
    grantRequests.add((listId: listId, userId: userId));
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

  @override
  Stream<List<Schedule>> watchListSchedules(String listId) =>
      const Stream.empty();

  @override
  Stream<Schedule?> watchSchedule(String scheduleId) => const Stream.empty();

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) =>
      const Stream.empty();

  @override
  Stream<List<Schedule>> watchUserSchedulesForMonth(
    String userId,
    DateTime displayMonth,
  ) =>
      const Stream.empty();
}

void main() {
  group('ListNotifier', () {
    late ProviderContainer container;
    late MockAuthRepository mockAuthRepository;
    late _TrackingListRepository listRepository;
    late MockUserRepository mockUserRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      listRepository = _TrackingListRepository();
      mockUserRepository = MockUserRepository();

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
          listRepositoryProvider.overrideWithValue(listRepository),
          userRepositoryProvider.overrideWithValue(mockUserRepository),
        ],
      );
    });

    tearDown(() {
      listRepository.dispose();
      mockAuthRepository.dispose();
      container.dispose();
    });

    test('ログアウト時にリスト購読を解除して初期状態へ戻す', () async {
      await container.read(authNotifierProvider.future);
      await container
          .read(listNotifierProvider.notifier)
          .watchUserLists('test-user-id');

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await mockAuthRepository.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(listRepository.cancelCount, 1);
      expect(container.read(listNotifierProvider).hasError, isFalse);
    });

    test('メンバー追加後に対象ユーザーへリスト予定の閲覧権限を付与する', () async {
      final scheduleRepository = _TrackingScheduleAccessGrantRepository();
      final scopedContainer = ProviderContainer(
        overrides: [
          listRepositoryProvider.overrideWithValue(listRepository),
          scheduleRepositoryProvider.overrideWithValue(scheduleRepository),
        ],
      );
      addTearDown(scopedContainer.dispose);

      await scopedContainer
          .read(listManagerProvider)
          .addMember('list-id', 'new-user-id');

      expect(
        listRepository.addedMembers,
        [(listId: 'list-id', userId: 'new-user-id')],
      );
      expect(
        scheduleRepository.grantRequests,
        [(listId: 'list-id', userId: 'new-user-id')],
      );
    });
  });
}
