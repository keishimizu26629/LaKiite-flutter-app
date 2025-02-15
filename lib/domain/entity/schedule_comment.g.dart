// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScheduleCommentImpl _$$ScheduleCommentImplFromJson(
        Map<String, dynamic> json) =>
    _$ScheduleCommentImpl(
      id: json['id'] as String,
      scheduleId: json['scheduleId'] as String,
      userId: json['userId'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userDisplayName: json['userDisplayName'] as String?,
      userPhotoUrl: json['userPhotoUrl'] as String?,
    );

Map<String, dynamic> _$$ScheduleCommentImplToJson(
        _$ScheduleCommentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheduleId': instance.scheduleId,
      'userId': instance.userId,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
      'userDisplayName': instance.userDisplayName,
      'userPhotoUrl': instance.userPhotoUrl,
    };
