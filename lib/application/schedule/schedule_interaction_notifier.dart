import 'dart:async';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/domain/entity/schedule_like.dart';
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
  StreamSubscription<List<ScheduleLike>>? _likesSubscription;
  StreamSubscription<List<ScheduleComment>>? _commentsSubscription;

  ScheduleInteractionNotifier(this._repository, this._scheduleId)
      : super(const ScheduleInteractionState()) {
    _initialize();
  }

  void _initialize() {
    _watchLikes();
    _watchComments();
  }

  void _watchLikes() {
    _likesSubscription?.cancel();
    _likesSubscription = _repository.watchLikes(_scheduleId).listen(
      (likes) {
        state = state.copyWith(likes: likes);
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

  Future<void> toggleLike(String userId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      if (state.isLikedByUser(userId)) {
        await _repository.removeLike(_scheduleId, userId);
      } else {
        await _repository.addLike(_scheduleId, userId);
      }
      
      state = state.copyWith(isLoading: false);
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
    _likesSubscription?.cancel();
    _commentsSubscription?.cancel();
    super.dispose();
  }
}