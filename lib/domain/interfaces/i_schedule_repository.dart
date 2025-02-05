import 'package:tarakite/domain/entity/schedule.dart';

abstract class IScheduleRepository {
  Future<List<Schedule>> getSchedules(String groupId);
  Future<Schedule> createSchedule({
    required String title,
    required DateTime dateTime,
    required String ownerId,
    required String groupId,
  });
  Future<void> updateSchedule(Schedule schedule);
  Future<void> deleteSchedule(String scheduleId);
  Stream<List<Schedule>> watchGroupSchedules(String groupId);
  Stream<List<Schedule>> watchUserSchedules(String userId);
}
