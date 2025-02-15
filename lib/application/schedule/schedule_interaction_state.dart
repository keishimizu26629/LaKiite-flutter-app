import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lakiite/domain/entity/schedule_like.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';

part 'schedule_interaction_state.freezed.dart';

@freezed
class ScheduleInteractionState with _$ScheduleInteractionState {
  const factory ScheduleInteractionState({
    @Default([]) List<ScheduleLike> likes,
    @Default([]) List<ScheduleComment> comments,
    @Default(false) bool isLoading,
    String? error,
  }) = _ScheduleInteractionState;

  const ScheduleInteractionState._();

  bool isLikedByUser(String userId) {
    return likes.any((like) => like.userId == userId);
  }

  int get likeCount => likes.length;
  int get commentCount => comments.length;
}