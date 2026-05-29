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
