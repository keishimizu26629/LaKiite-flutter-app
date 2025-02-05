import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tarakite/application/schedule/schedule_state.dart';
import 'package:tarakite/domain/entity/schedule.dart';
import 'package:tarakite/presentation/presentation_provider.dart';

part 'schedule_notifier.g.dart';

@riverpod
class ScheduleNotifier extends AutoDisposeAsyncNotifier<ScheduleState> {
  @override
  Future<ScheduleState> build() async {
    return const ScheduleState.initial();
  }

  Future<void> createSchedule({
    required String title,
    required DateTime dateTime,
    required String ownerId,
    required String groupId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(scheduleRepositoryProvider).createSchedule(
            title: title,
            dateTime: dateTime,
            ownerId: ownerId,
            groupId: groupId,
          );
      await fetchSchedules(groupId);
    } catch (e) {
      state = AsyncValue.data(ScheduleState.error(e.toString()));
    }
  }

  Future<void> fetchSchedules(String groupId) async {
    state = const AsyncValue.loading();
    try {
      final schedules = await ref.read(scheduleRepositoryProvider).getSchedules(groupId);
      state = AsyncValue.data(ScheduleState.loaded(schedules));
    } catch (e) {
      state = AsyncValue.data(ScheduleState.error(e.toString()));
    }
  }

  Future<void> updateSchedule(Schedule schedule) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(scheduleRepositoryProvider).updateSchedule(schedule);
      await fetchSchedules(schedule.groupId);
    } catch (e) {
      state = AsyncValue.data(ScheduleState.error(e.toString()));
    }
  }

  Future<void> deleteSchedule(String scheduleId, String groupId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(scheduleRepositoryProvider).deleteSchedule(scheduleId);
      await fetchSchedules(groupId);
    } catch (e) {
      state = AsyncValue.data(ScheduleState.error(e.toString()));
    }
  }

  void watchGroupSchedules(String groupId) {
    ref.read(scheduleRepositoryProvider).watchGroupSchedules(groupId).listen(
      (schedules) {
        state = AsyncValue.data(ScheduleState.loaded(schedules));
      },
      onError: (error) {
        state = AsyncValue.data(ScheduleState.error(error.toString()));
      },
    );
  }

  void watchUserSchedules(String userId) {
    ref.read(scheduleRepositoryProvider).watchUserSchedules(userId).listen(
      (schedules) {
        state = AsyncValue.data(ScheduleState.loaded(schedules));
      },
      onError: (error) {
        state = AsyncValue.data(ScheduleState.error(error.toString()));
      },
    );
  }
}
