import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart' as auth;
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/schedule/schedule_interaction_notifier.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';
import 'package:lakiite/presentation/calendar/schedule_detail_page.dart';

import '../../mock/base_mock.dart';
import '../../mock/providers/test_providers.dart';
import '../../utils/test_utils.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ja_JP', null);
  });

  setUp(() {
    TestProviders.reset();
  });

  testWidgets('自分の予定には公開先リストボタンを表示する', (tester) async {
    final overrides = [
      ...TestProviders.forScheduleCreation,
      auth.authNotifierProvider.overrideWith(
        () => _StubAuthNotifier(
          AuthState.authenticated(BaseMock.createTestUser()),
        ),
      ),
      repositorySessionKeyProvider.overrideWith(
        (ref) => Stream.value(BaseMock.testUserId),
      ),
      scheduleInteractionRepositoryProvider.overrideWithValue(
        _EmptyScheduleInteractionRepository(),
      ),
      scheduleInteractionNotifierProvider.overrideWith((ref, scheduleId) {
        return ScheduleInteractionNotifier(
          ref.watch(scheduleInteractionRepositoryProvider),
          scheduleId,
          ref,
          enablePushNotifications: false,
        );
      }),
    ];
    final schedule = BaseMock.createTestSchedule().copyWith(
      sharedLists: const ['list-1'],
    );
    TestProviders.mockScheduleRepository.addTestSchedule(schedule);

    await tester.pumpWidget(
      TestUtils.createTestApp(
        overrides: overrides,
        child: ScheduleDetailPage(schedule: schedule),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(
        find.byKey(const Key('schedule_shared_lists_button')), findsOneWidget);
    expect(find.text('公開先リスト'), findsOneWidget);
  });

  testWidgets('他人の予定には公開先リストボタンを表示しない', (tester) async {
    final overrides = [
      ...TestProviders.forScheduleCreation,
      auth.authNotifierProvider.overrideWith(
        () => _StubAuthNotifier(
          AuthState.authenticated(BaseMock.createTestUser()),
        ),
      ),
      repositorySessionKeyProvider.overrideWith(
        (ref) => Stream.value(BaseMock.testUserId),
      ),
      scheduleInteractionRepositoryProvider.overrideWithValue(
        _EmptyScheduleInteractionRepository(),
      ),
      scheduleInteractionNotifierProvider.overrideWith((ref, scheduleId) {
        return ScheduleInteractionNotifier(
          ref.watch(scheduleInteractionRepositoryProvider),
          scheduleId,
          ref,
          enablePushNotifications: false,
        );
      }),
    ];
    final schedule = BaseMock.createTestSchedule(
      id: 'other-user-schedule-id',
      ownerId: 'other-user',
      ownerDisplayName: 'ほかのユーザー',
    ).copyWith(
      sharedLists: const ['list-1'],
    );
    TestProviders.mockScheduleRepository.addTestSchedule(schedule);

    await tester.pumpWidget(
      TestUtils.createTestApp(
        overrides: overrides,
        child: ScheduleDetailPage(schedule: schedule),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('schedule_shared_lists_button')), findsNothing);
  });
}

class _StubAuthNotifier extends auth.AuthNotifier {
  _StubAuthNotifier(this._state);

  final AuthState _state;

  @override
  FutureOr<AuthState> build() => _state;
}

class _EmptyScheduleInteractionRepository
    implements IScheduleInteractionRepository {
  @override
  Future<String> addComment(String scheduleId, String userId, String content) =>
      Future.value('comment-id');

  @override
  Future<String> addReaction(
    String scheduleId,
    String userId,
    ReactionType type,
  ) =>
      Future.value('reaction-id');

  @override
  Future<void> deleteComment(String scheduleId, String commentId) async {}

  @override
  Future<int> getCommentCount(String scheduleId) => Future.value(0);

  @override
  Future<List<ScheduleComment>> getComments(String scheduleId) =>
      Future.value([]);

  @override
  Future<int> getReactionCount(String scheduleId) => Future.value(0);

  @override
  Future<List<ScheduleReaction>> getReactions(String scheduleId) =>
      Future.value([]);

  @override
  Future<void> removeReaction(String scheduleId, String userId) async {}

  @override
  Future<void> updateComment(
    String scheduleId,
    String commentId,
    String content,
  ) async {}

  @override
  Stream<List<ScheduleComment>> watchComments(String scheduleId) =>
      Stream.value([]);

  @override
  Stream<List<ScheduleReaction>> watchReactions(String scheduleId) =>
      Stream.value([]);
}
