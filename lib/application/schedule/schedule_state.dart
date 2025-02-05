import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tarakite/domain/entity/schedule.dart';

part 'schedule_state.freezed.dart';

@freezed
class ScheduleState with _$ScheduleState {
  const factory ScheduleState.initial() = _Initial;
  const factory ScheduleState.loading() = _Loading;
  const factory ScheduleState.loaded(List<Schedule> schedules) = _Loaded;
  const factory ScheduleState.error(String message) = _Error;
}
