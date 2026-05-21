import 'package:lakiite/domain/entity/reaction.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';

/// スケジュールリアクションの永続化を抽象化する repository。
abstract class ReactionRepository {
  /// 指定したスケジュールに紐づくリアクション一覧を取得する。
  Future<List<Reaction>> getReactionsForSchedule(String scheduleId);

  /// 指定したユーザーのリアクションを追加または更新する。
  Future<void> addReaction(
    String scheduleId,
    String userId,
    ReactionType type,
  );

  /// 指定したユーザーのリアクションを削除する。
  Future<void> removeReaction(String scheduleId, String userId);
}
