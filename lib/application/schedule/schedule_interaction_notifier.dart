import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';
import 'package:lakiite/application/schedule/schedule_interaction_state.dart';
import 'package:lakiite/infrastructure/schedule_interaction_repository.dart';

final scheduleInteractionRepositoryProvider = Provider<IScheduleInteractionRepository>(
  (ref) => ScheduleInteractionRepository(),
);

final scheduleInteractionNotifierProvider = StateNotifierProvider.family<
    ScheduleInteractionNotifier, ScheduleInteractionState, String>(
  (ref, scheduleId) => ScheduleInteractionNotifier(
    ref.watch(scheduleInteractionRepositoryProvider),
    scheduleId,
  ),
);

class ScheduleInteractionNotifier extends StateNotifier<ScheduleInteractionState> {
  final IScheduleInteractionRepository _repository;
  final String _scheduleId;
  StreamSubscription<List<ScheduleReaction>>? _reactionsSubscription;
  StreamSubscription<List<ScheduleComment>>? _commentsSubscription;

  ScheduleInteractionNotifier(this._repository, this._scheduleId)
      : super(const ScheduleInteractionState()) {
    _initialize();
  }

  void _initialize() {
    _watchReactions();
    _watchComments();
  }

  void _watchReactions() {
    _reactionsSubscription?.cancel();
    _reactionsSubscription = _repository.watchReactions(_scheduleId).listen(
      (reactions) {
        print('Updating state with reactions: $reactions');
        print('Current state reactions count: ${state.reactions.length}');
        state = state.copyWith(reactions: reactions);
        print('New state reactions count: ${state.reactions.length}');
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  void _watchComments() {
    _commentsSubscription?.cancel();
    _commentsSubscription = _repository.watchComments(_scheduleId).listen(
      (comments) {
        state = state.copyWith(comments: comments);
      },
      onError: (error) {
        state = state.copyWith(error: error.toString());
      },
    );
  }

  Future<void> toggleReaction(String userId, ReactionType type) async {
    try {
      print('toggleReaction called - userId: $userId, type: $type');
      state = state.copyWith(isLoading: true, error: null);
      
      final currentReaction = state.getUserReaction(userId);
      print('Current reaction: $currentReaction');
      
      if (currentReaction != null) {
        if (currentReaction.type == type) {
          print('Removing same reaction');
          await _repository.removeReaction(_scheduleId, userId);
        } else {
          print('Updating to different reaction');
          await _repository.removeReaction(_scheduleId, userId);
          await _repository.addReaction(_scheduleId, userId, type);
        }
      } else {
        print('Adding new reaction');
        await _repository.addReaction(_scheduleId, userId, type);
      }
      
      print('Current state reactions: ${state.reactions}');
      state = state.copyWith(isLoading: false);
      print('Updated state reactions: ${state.reactions}');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addComment(String userId, String content) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.addComment(_scheduleId, userId, content);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _repository.deleteComment(_scheduleId, commentId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  @override
  void dispose() {
    _reactionsSubscription?.cancel();
    _commentsSubscription?.cancel();
    super.dispose();
  }
}