// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReactionImpl _$$ReactionImplFromJson(Map<String, dynamic> json) =>
    _$ReactionImpl(
      id: json['id'] as String,
      scheduleId: json['scheduleId'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      userDisplayName: json['userDisplayName'] as String,
      userPhotoUrl: json['userPhotoUrl'] as String?,
      createdAt:
          const TimestampConverter().fromJson(json['createdAt'] as Timestamp),
    );

Map<String, dynamic> _$$ReactionImplToJson(_$ReactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'scheduleId': instance.scheduleId,
      'userId': instance.userId,
      'type': instance.type,
      'userDisplayName': instance.userDisplayName,
      'userPhotoUrl': instance.userPhotoUrl,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
