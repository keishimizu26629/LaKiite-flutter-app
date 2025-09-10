import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';

/// スケジュールの相互作用（リアクション・コメント）に関するリポジトリのインターフェース
abstract class ScheduleInteractionRepository {
  /// 指定された[scheduleId]と[commentId]のコメントを削除する
  Future<void> deleteComment(String scheduleId, String commentId);

  /// 指定された[scheduleId]と[commentId]のコメントを更新する
  Future<void> updateComment(
      String scheduleId, String commentId, String content);

  /// 指定された[scheduleId]のスケジュールにリアクションを追加
  Future<String> addReaction(
      String scheduleId, String userId, ReactionType type);

  /// 指定された[scheduleId]のスケジュールからリアクションを削除
  Future<void> removeReaction(String scheduleId, String userId);

  /// 指定された[scheduleId]のスケジュールのリアクションを取得
  Future<List<ScheduleReaction>> getReactions(String scheduleId);

  /// 指定された[scheduleId]のスケジュールのリアクションをリアルタイムで監視
  Stream<List<ScheduleReaction>> watchReactions(String scheduleId);

  /// 指定された[scheduleId]のスケジュールにコメントを追加
  Future<String> addComment(String scheduleId, String userId, String content);

  /// 指定された[scheduleId]のスケジュールのコメントを取得
  Future<List<ScheduleComment>> getComments(String scheduleId);

  /// 指定された[scheduleId]のスケジュールのコメントをリアルタイムで監視
  Stream<List<ScheduleComment>> watchComments(String scheduleId);
}
