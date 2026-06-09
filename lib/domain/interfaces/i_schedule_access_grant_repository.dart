abstract class IScheduleAccessGrantRepository {
  Future<void> grantListSchedulesAccessToUser({
    required String listId,
    required String userId,
  });
}
