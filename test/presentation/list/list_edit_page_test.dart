import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/interfaces/i_list_repository.dart';
import 'package:lakiite/presentation/list/list_edit_page.dart';
import 'package:lakiite/presentation/list/list_providers.dart';

import '../../mock/repository/mock_user_repository.dart';

void main() {
  testWidgets('リスト編集は保存時に最新のmemberIdsを保持する', (tester) async {
    final listController = StreamController<UserList?>();
    final listRepository = _CapturingListRepository();
    final userRepository = MockUserRepository()
      ..addTestUser(
        UserModel.create(id: 'member-1', name: 'メンバー1', displayName: 'メンバー一郎'),
      )
      ..addTestUser(
        UserModel.create(id: 'member-2', name: 'メンバー2', displayName: 'メンバー二郎'),
      );
    final initialList = _list(memberIds: const ['member-1']);
    final latestList = _list(memberIds: const ['member-1', 'member-2']);

    addTearDown(listController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listRepositoryProvider.overrideWithValue(listRepository),
          userRepositoryProvider.overrideWithValue(userRepository),
          listStreamProvider.overrideWith(
            (ref, listId) => listController.stream,
          ),
        ],
        child: MaterialApp(home: ListEditPage(list: initialList)),
      ),
    );

    listController.add(latestList);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(listRepository.updatedList, isNotNull);
    expect(listRepository.updatedList!.memberIds, ['member-1', 'member-2']);
  });
}

class _CapturingListRepository implements IListRepository {
  UserList? updatedList;

  @override
  Future<void> updateList(UserList list) async {
    updatedList = list;
  }

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
  Stream<UserList?> watchList(String listId) => const Stream.empty();

  @override
  Stream<List<UserList>> watchUserLists(String ownerId) => const Stream.empty();
}

UserList _list({required List<String> memberIds}) {
  return UserList(
    id: 'list-1',
    listName: 'テストリスト',
    ownerId: 'owner',
    memberIds: memberIds,
    createdAt: DateTime(2026, 5, 30),
  );
}
