import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/friend/friend_providers.dart';
import 'package:lakiite/presentation/list/list_member_invite_page.dart';
import 'package:lakiite/presentation/list/list_providers.dart';

import '../../mock/repository/mock_auth_repository.dart';

void main() {
  testWidgets('メンバー追加は最新のmemberIdsで既存メンバーを選択不可にする', (tester) async {
    final authRepository = MockAuthRepository();
    final listController = StreamController<UserList?>();
    final currentUser = UserModel.create(
      id: 'owner',
      name: 'オーナー',
      displayName: 'オーナー',
    );
    final initialList = _list(memberIds: const ['member-1']);
    final latestList = _list(memberIds: const ['member-1', 'member-2']);
    final friends = [
      UserModel.create(
        id: 'member-2',
        name: 'メンバー2',
        displayName: 'メンバー二郎',
      ).publicProfile,
      UserModel.create(
        id: 'member-3',
        name: 'メンバー3',
        displayName: 'メンバー三郎',
      ).publicProfile,
    ];

    addTearDown(listController.close);
    addTearDown(authRepository.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          userFriendsStreamProvider.overrideWith(
            (ref) => Stream.value(friends),
          ),
          listStreamProvider.overrideWith(
            (ref, listId) => listController.stream,
          ),
        ],
        child: MaterialApp(home: ListMemberInvitePage(list: initialList)),
      ),
    );

    authRepository.setCurrentUser(currentUser);
    listController.add(latestList);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('メンバー二郎'));
    await tester.pump();

    final addButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '選択したメンバー(0名)を追加'),
    );
    expect(addButton.onPressed, isNull);
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
