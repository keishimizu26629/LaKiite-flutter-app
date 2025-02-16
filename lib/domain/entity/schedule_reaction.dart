import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'schedule_reaction.freezed.dart';
part 'schedule_reaction.g.dart';

enum ReactionType {
  @JsonValue('going')
  going, // 行きます！🙋
  @JsonValue('thinking')
  thinking, // 考え中！🤔
}

@freezed
@JsonSerializable()
class ScheduleReaction with _$ScheduleReaction {
  const factory ScheduleReaction({
    required String id,
    required String userId,
    required ReactionType type,
    required DateTime createdAt,
    String? userDisplayName,
    String? userPhotoUrl,
  }) = _ScheduleReaction;

  factory ScheduleReaction.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    return _$ScheduleReactionFromJson({
      ...json,
      'createdAt': createdAt is DateTime
          ? createdAt.toIso8601String()
          : (createdAt as Timestamp).toDate().toIso8601String(),
    });
  }
}