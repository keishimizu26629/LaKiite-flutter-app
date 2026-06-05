import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/domain/entity/display_list.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/list/display_list_detail_page.dart';
import 'package:lakiite/presentation/list/display_list_providers.dart';

import '../../mock/repository/mock_user_repository.dart';

void main() {
  testWidgets('表示用リスト詳細は同じメンバーの公開プロフィールを再取得しない', (tester) async {
    final displayListController = StreamController<List<DisplayList>>();
    final userRepository = _CountingUserRepository()
      ..addTestUser(
        UserModel.create(id: 'member-1', name: 'メンバー1', displayName: 'メンバー一郎'),
      );
    final initialDisplayList = _displayList(
      name: '公開リスト',
      memberIds: const ['member-1'],
    );
    final updatedDisplayList = _displayList(
      name: '公開リスト 更新後',
      memberIds: const ['member-1'],
    );

    addTearDown(displayListController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(userRepository),
          userDisplayListsStreamProvider.overrideWith(
            (ref) => displayListController.stream,
          ),
        ],
        child: MaterialApp(
          home: DisplayListDetailPage(displayList: initialDisplayList),
        ),
      ),
    );

    displayListController.add([initialDisplayList]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('メンバー一郎'), findsOneWidget);
    expect(userRepository.getFriendPublicProfileCallCount('member-1'), 1);

    displayListController.add([updatedDisplayList]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('公開リスト 更新後'), findsOneWidget);
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

DisplayList _displayList({
  required String name,
  required List<String> memberIds,
}) {
  return DisplayList(
    id: 'display-list-1',
    name: name,
    ownerId: 'owner',
    colorKey: 'blue',
    memberIds: memberIds,
    createdAt: DateTime(2026, 6, 6),
    updatedAt: DateTime(2026, 6, 6),
  );
}
