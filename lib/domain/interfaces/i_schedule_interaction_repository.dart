import 'package:lakiite/domain/entity/schedule_like.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';

abstract class IScheduleInteractionRepository {
  // いいね関連
  Future<List<ScheduleLike>> getLikes(String scheduleId);
  Future<void> addLike(String scheduleId, String userId);
  Future<void> removeLike(String scheduleId, String userId);
  Stream<List<ScheduleLike>> watchLikes(String scheduleId);

  // コメント関連
  Future<List<ScheduleComment>> getComments(String scheduleId);
  Future<void> addComment(String scheduleId, String userId, String content);
  Future<void> deleteComment(String scheduleId, String commentId);
  Stream<List<ScheduleComment>> watchComments(String scheduleId);
}