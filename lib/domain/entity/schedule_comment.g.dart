// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleComment _$ScheduleCommentFromJson(Map<String, dynamic> json) =>
    ScheduleComment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userDisplayName: json['userDisplayName'] as String?,
      userPhotoUrl: json['userPhotoUrl'] as String?,
    );

Map<String, dynamic> _$ScheduleCommentToJson(ScheduleComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
      'userDisplayName': instance.userDisplayName,
      'userPhotoUrl': instance.userPhotoUrl,
    };
