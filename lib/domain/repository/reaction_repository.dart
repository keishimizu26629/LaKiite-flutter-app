import 'package:lakiite/domain/entity/reaction.dart';

abstract class ReactionRepository {
  Future<List<Reaction>> getReactionsForSchedule(String scheduleId);
  Future<void> addReaction(String scheduleId, String userId, String type);
  Future<void> removeReaction(String scheduleId, String userId);
}
