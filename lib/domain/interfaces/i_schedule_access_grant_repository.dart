import 'package:lakiite/domain/entity/list.dart';

abstract class IScheduleAccessGrantRepository {
  Future<void> grantListSchedulesAccessToUser({
    required String listId,
    required String userId,
  });

  Future<void> syncListSchedulesAccess({
    required UserList beforeList,
    required UserList afterList,
  });
}
