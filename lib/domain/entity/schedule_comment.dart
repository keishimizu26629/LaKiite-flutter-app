import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'schedule_comment.freezed.dart';
part 'schedule_comment.g.dart';

@freezed
@JsonSerializable()
class ScheduleComment with _$ScheduleComment {
  const factory ScheduleComment({
    required String id,
    required String userId,
    required String content,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(false) bool isEdited,
    String? userDisplayName,
    String? userPhotoUrl,
  }) = _ScheduleComment;

  factory ScheduleComment.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];

    return _$ScheduleCommentFromJson({
      ...json,
      'createdAt': createdAt is DateTime
          ? createdAt.toIso8601String()
          : (createdAt as Timestamp).toDate().toIso8601String(),
      'updatedAt': updatedAt == null
          ? null
          : updatedAt is DateTime
              ? updatedAt.toIso8601String()
              : (updatedAt as Timestamp).toDate().toIso8601String(),
      'isEdited': json['isEdited'] ?? false,
    });
  }
}
