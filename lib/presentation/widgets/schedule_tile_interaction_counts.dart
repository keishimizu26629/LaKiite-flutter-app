import 'package:lakiite/application/schedule/schedule_interaction_state.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';

class ScheduleTileInteractionCounts {
  const ScheduleTileInteractionCounts({
    required this.reactionCounts,
    required this.reactionCount,
    required this.commentCount,
    required this.isLoading,
  });

  factory ScheduleTileInteractionCounts.resolve({
    required Schedule schedule,
    required ScheduleInteractionState interactionState,
  }) {
    final hasLiveInteractions =
        !interactionState.isLoading && interactionState.error == null;
    final liveReactionCounts = hasLiveInteractions
        ? interactionState.reactionCounts
        : const <ReactionType, int>{};

    return ScheduleTileInteractionCounts(
      reactionCounts: liveReactionCounts,
      reactionCount: hasLiveInteractions
          ? liveReactionCounts.values.fold<int>(
              0,
              (sum, count) => sum + count,
            )
          : schedule.reactionCount,
      commentCount: hasLiveInteractions
          ? interactionState.commentCount
          : schedule.commentCount,
      isLoading: !hasLiveInteractions,
    );
  }

  final Map<ReactionType, int> reactionCounts;
  final int reactionCount;
  final int commentCount;
  final bool isLoading;
}
