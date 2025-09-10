import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';

part 'schedule_interaction_state.freezed.dart';

@freezed
class ScheduleInteractionState with _$ScheduleInteractionState {
  const factory ScheduleInteractionState({
    @Default([]) List<ScheduleReaction> reactions,
    @Default([]) List<ScheduleComment> comments,
    @Default(false) bool isLoading,
    String? error,
  }) = _ScheduleInteractionState;

  const ScheduleInteractionState._();

  ScheduleReaction? getUserReaction(String userId) {
    return reactions.cast<ScheduleReaction?>().firstWhere(
          (reaction) => reaction?.userId == userId,
          orElse: () => null,
        );
  }

  Map<ReactionType, int> get reactionCounts {
    final counts = <ReactionType, int>{
      ReactionType.going: 0,
      ReactionType.thinking: 0,
    };
    for (final reaction in reactions) {
      counts[reaction.type] = (counts[reaction.type] ?? 0) + 1;
    }
    return counts;
  }

  int get commentCount => comments.length;
}
