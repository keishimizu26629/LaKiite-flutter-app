import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_like.freezed.dart';
part 'schedule_like.g.dart';

@freezed
class ScheduleLike with _$ScheduleLike {
  const factory ScheduleLike({
    required String id,
    required String scheduleId,
    required String userId,
    required DateTime createdAt,
  }) = _ScheduleLike;

  factory ScheduleLike.fromJson(Map<String, dynamic> json) =>
      _$ScheduleLikeFromJson(json);
}
