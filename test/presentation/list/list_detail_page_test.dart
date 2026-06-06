import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/list/list_detail_page.dart';
import 'package:lakiite/presentation/list/list_providers.dart';

import '../../mock/repository/mock_user_repository.dart';

void main() {
  testWidgets('リスト詳細はlistStreamProviderの最新メンバーを表示する', (tester) async {
    final listController = StreamController<UserList?>();
    final userRepository = MockUserRepository()
      ..addTestUser(
        UserModel.create(id: 'member-1', name: 'メンバー1', displayName: 'メンバー一郎'),
      )
      ..addTestUser(
        UserModel.create(id: 'member-2', name: 'メンバー2', displayName: 'メンバー二郎'),
      );
    final initialList = _list(memberIds: const ['member-1']);
    final updatedList = _list(memberIds: const ['member-1', 'member-2']);

    addTearDown(listController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(userRepository),
          listStreamProvider.overrideWith(
            (ref, listId) => listController.stream,
          ),
        ],
        child: MaterialApp(home: ListDetailPage(list: initialList)),
      ),
    );

    listController.add(initialList);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('1人'), findsOneWidget);
    expect(find.text('メンバー一郎'), findsOneWidget);
    expect(find.text('メンバー二郎'), findsNothing);

    listController.add(updatedList);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('2人'), findsOneWidget);
    expect(find.text('メンバー一郎'), findsOneWidget);
    expect(find.text('メンバー二郎'), findsOneWidget);
  });

  testWidgets('リスト詳細は同じメンバーの公開プロフィールを再取得しない', (tester) async {
    final listController = StreamController<UserList?>();
    final userRepository = _CountingUserRepository()
      ..addTestUser(
        UserModel.create(id: 'member-1', name: 'メンバー1', displayName: 'メンバー一郎'),
      );
    final initialList = _list(memberIds: const ['member-1']);
    final updatedList = initialList.copyWith(listName: 'テストリスト 更新後');

    addTearDown(listController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(userRepository),
          listStreamProvider.overrideWith(
            (ref, listId) => listController.stream,
          ),
        ],
        child: MaterialApp(home: ListDetailPage(list: initialList)),
      ),
    );

    listController.add(initialList);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('メンバー一郎'), findsOneWidget);
    expect(userRepository.getFriendPublicProfileCallCount('member-1'), 1);

    listController.add(updatedList);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('テストリスト 更新後'), findsOneWidget);
    expect(find.text('メンバー一郎'), findsOneWidget);
    expect(userRepository.getFriendPublicProfileCallCount('member-1'), 1);
  });
}

class _CountingUserRepository extends MockUserRepository {
  final Map<String, int> _getFriendPublicProfileCallCounts = {};

  int getFriendPublicProfileCallCount(String id) {
    return _getFriendPublicProfileCallCounts[id] ?? 0;
  }

  @override
  Future<PublicUserModel?> getFriendPublicProfile(String id) {
    _getFriendPublicProfileCallCounts[id] =
        getFriendPublicProfileCallCount(id) + 1;
    return super.getFriendPublicProfile(id);
  }
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
