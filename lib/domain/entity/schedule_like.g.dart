// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_like.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScheduleLikeImpl _$$ScheduleLikeImplFromJson(Map<String, dynamic> json) =>
    _$ScheduleLikeImpl(
      id: json['id'] as String,
      scheduleId: json['scheduleId'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ScheduleLikeImplToJson(_$ScheduleLikeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheduleId': instance.scheduleId,
      'userId': instance.userId,
      'createdAt': instance.createdAt.toIso8601String(),
    };
