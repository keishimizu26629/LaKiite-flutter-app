import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/reaction.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/value/user_id.dart';
import 'package:lakiite/presentation/calendar/widgets/reaction_users_sheet.dart';

void main() {
  testWidgets('リアクションしたユーザー名とリアクション種別を表示する', (tester) async {
    final reactions = [
      Reaction(
        id: 'reaction-1',
        scheduleId: 'schedule-1',
        userId: 'user-1',
        type: ReactionType.going,
        userDisplayName: 'ユーザー1',
        createdAt: DateTime(2026, 5, 1),
      ),
      Reaction(
        id: 'reaction-2',
        scheduleId: 'schedule-1',
        userId: 'user-2',
        type: ReactionType.thinking,
        userDisplayName: 'ユーザー2',
        createdAt: DateTime(2026, 5, 1),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReactionUsersSheet(
            reactions: reactions,
            usersFuture: Future.value([
              _publicUser(id: 'user-1', displayName: 'ユーザー1'),
              _publicUser(id: 'user-2', displayName: 'ユーザー2'),
            ]),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('リアクションした人'), findsOneWidget);
    expect(find.text('ユーザー1'), findsOneWidget);
    expect(find.text('ユーザー2'), findsOneWidget);
    expect(find.text('🙋'), findsOneWidget);
    expect(find.text('🤔'), findsOneWidget);
  });

  testWidgets('リアクションしたユーザーが削除済みの場合は退会済みユーザーとして表示する', (tester) async {
    final reactions = [
      Reaction(
        id: 'reaction-1',
        scheduleId: 'schedule-1',
        userId: 'deleted-user-1',
        type: ReactionType.going,
        userDisplayName: '削除前の名前',
        createdAt: DateTime(2026, 5, 1),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReactionUsersSheet(
            reactions: reactions,
            usersFuture: Future.value([]),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('退会済みユーザー'), findsOneWidget);
    expect(find.text('削除前の名前'), findsNothing);
    expect(find.text('🙋'), findsOneWidget);
  });
}

PublicUserModel _publicUser({required String id, required String displayName}) {
  return PublicUserModel(
    id: id,
    displayName: displayName,
    searchId: UserId('USRTEST1'),
    iconUrl: null,
    shortBio: null,
  );
}
