import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/application/schedule/schedule_interaction_state.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/presentation/widgets/schedule_tile_interaction_counts.dart';

import '../../mock/base_mock.dart';

void main() {
  test('ライブなインタラクション状態がScheduleの古いcountより優先される', () {
    final schedule = BaseMock.createTestSchedule().copyWith(
      reactionCount: 0,
      commentCount: 0,
    );
    final interactionState = ScheduleInteractionState(
      reactions: [
        _reaction(id: 'reaction-1', userId: 'user-1'),
        _reaction(
          id: 'reaction-2',
          userId: 'user-2',
          type: ReactionType.thinking,
        ),
      ],
      comments: [
        _comment(id: 'comment-1'),
        _comment(id: 'comment-2'),
        _comment(id: 'comment-3'),
      ],
    );

    final counts = ScheduleTileInteractionCounts.resolve(
      schedule: schedule,
      interactionState: interactionState,
    );

    expect(counts.reactionCount, 2);
    expect(counts.commentCount, 3);
    expect(counts.reactionCounts[ReactionType.going], 1);
    expect(counts.reactionCounts[ReactionType.thinking], 1);
    expect(counts.isLoading, isFalse);
  });

  test('インタラクション状態が未取得の場合はScheduleのcountを使う', () {
    final schedule = BaseMock.createTestSchedule().copyWith(
      reactionCount: 4,
      commentCount: 5,
    );
    const interactionState = ScheduleInteractionState(isLoading: true);

    final counts = ScheduleTileInteractionCounts.resolve(
      schedule: schedule,
      interactionState: interactionState,
    );

    expect(counts.reactionCount, 4);
    expect(counts.commentCount, 5);
    expect(counts.reactionCounts, isEmpty);
    expect(counts.isLoading, isTrue);
  });
}

ScheduleReaction _reaction({
  required String id,
  required String userId,
  ReactionType type = ReactionType.going,
}) {
  return ScheduleReaction(
    id: id,
    userId: userId,
    type: type,
    createdAt: DateTime(2026, 6, 14),
  );
}

ScheduleComment _comment({required String id}) {
  return ScheduleComment(
    id: id,
    userId: 'comment-user',
    content: 'コメント',
    createdAt: DateTime(2026, 6, 14),
  );
}
