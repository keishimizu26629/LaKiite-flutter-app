import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/presentation/calendar/schedule_shared_lists_page.dart';
import 'package:lakiite/presentation/list/list_providers.dart';
import 'package:lakiite/presentation/user/user_providers.dart';

import '../../mock/base_mock.dart';
import '../../mock/providers/test_providers.dart';
import '../../utils/test_utils.dart';

void main() {
  setUp(() {
    TestProviders.reset();
  });

  testWidgets('公開先リストページは予定のsharedLists順にリストとメンバーを表示する', (tester) async {
    final listA = _list(
      id: 'list-a',
      name: 'Aリスト',
      memberIds: const ['friend-1'],
    );
    final listB = _list(
      id: 'list-b',
      name: 'Bリスト',
      memberIds: const ['friend-2'],
    );
    final overrides = [
      ...TestProviders.authenticatedWithFriends,
      userListsStreamProvider
          .overrideWith((ref) => Stream.value([listA, listB])),
      publicUserProvider.overrideWith((ref, userId) {
        return Future.value(_publicUsers[userId]);
      }),
    ];
    final schedule = BaseMock.createTestSchedule().copyWith(
      sharedLists: const ['list-b', 'list-a'],
    );

    await tester.pumpWidget(
      TestUtils.createTestApp(
        overrides: overrides,
        child: ScheduleSharedListsPage(schedule: schedule),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();

    expect(find.text('公開先リスト'), findsOneWidget);
    expect(find.text('Bリスト'), findsOneWidget);
    expect(find.text('Aリスト'), findsOneWidget);
    expect(find.text('友達二郎'), findsOneWidget);
    expect(find.text('友達一郎'), findsOneWidget);

    final listBTop = tester.getTopLeft(find.text('Bリスト')).dy;
    final listATop = tester.getTopLeft(find.text('Aリスト')).dy;
    expect(listBTop, lessThan(listATop));
  });

  testWidgets('公開先リストページは公開先リストがない場合に空状態を表示する', (tester) async {
    final overrides = [
      ...TestProviders.authenticated,
      userListsStreamProvider.overrideWith((ref) => Stream.value([])),
    ];
    final schedule = BaseMock.createTestSchedule();

    await tester.pumpWidget(
      TestUtils.createTestApp(
        overrides: overrides,
        child: ScheduleSharedListsPage(schedule: schedule),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('公開先リストがありません'), findsOneWidget);
  });
}

final _publicUsers = {
  'friend-1': BaseMock.createTestUser(
    id: 'friend-1',
    name: '友達1',
    displayName: '友達一郎',
  ).publicProfile,
  'friend-2': BaseMock.createTestUser(
    id: 'friend-2',
    name: '友達2',
    displayName: '友達二郎',
  ).publicProfile,
};

UserList _list({
  required String id,
  required String name,
  required List<String> memberIds,
}) {
  return UserList(
    id: id,
    listName: name,
    ownerId: BaseMock.testUserId,
    memberIds: memberIds,
    createdAt: DateTime(2026, 6, 6),
  );
}
