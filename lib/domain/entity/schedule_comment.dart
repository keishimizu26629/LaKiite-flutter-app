import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule_comment.freezed.dart';
part 'schedule_comment.g.dart';

@freezed
class ScheduleComment with _$ScheduleComment {
  const factory ScheduleComment({
    required String id,
    required String scheduleId,
    required String userId,
    required String content,
    required DateTime createdAt,
    String? userDisplayName,
    String? userPhotoUrl,
  }) = _ScheduleComment;

  factory ScheduleComment.fromJson(Map<String, dynamic> json) =>
      _$ScheduleCommentFromJson(json);
}