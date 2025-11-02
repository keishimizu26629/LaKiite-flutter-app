import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';

abstract class IScheduleInteractionRepository {
  // リアクション関連
  Future<List<ScheduleReaction>> getReactions(String scheduleId);
  Future<String> addReaction(
      String scheduleId, String userId, ReactionType type);
  Future<void> removeReaction(String scheduleId, String userId);
  Stream<List<ScheduleReaction>> watchReactions(String scheduleId);

  // リアクション数の取得
  Future<int> getReactionCount(String scheduleId);

  // コメント関連
  Future<List<ScheduleComment>> getComments(String scheduleId);
  Future<String> addComment(String scheduleId, String userId, String content);
  Future<void> deleteComment(String scheduleId, String commentId);
  Future<void> updateComment(
      String scheduleId, String commentId, String content);
  Stream<List<ScheduleComment>> watchComments(String scheduleId);

  // コメント数の取得
  Future<int> getCommentCount(String scheduleId);
}
