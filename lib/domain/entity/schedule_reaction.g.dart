// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_reaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleReaction _$ScheduleReactionFromJson(Map<String, dynamic> json) =>
    ScheduleReaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: $enumDecode(_$ReactionTypeEnumMap, json['type']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      userDisplayName: json['userDisplayName'] as String?,
      userPhotoUrl: json['userPhotoUrl'] as String?,
    );

const _$ReactionTypeEnumMap = {
  ReactionType.going: 'going',
  ReactionType.thinking: 'thinking',
};
