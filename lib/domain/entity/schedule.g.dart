// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ScheduleImpl _$$ScheduleImplFromJson(Map<String, dynamic> json) =>
    _$ScheduleImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      location: json['location'] as String?,
      startDateTime: DateTime.parse(json['startDateTime'] as String),
      endDateTime: DateTime.parse(json['endDateTime'] as String),
      ownerId: json['ownerId'] as String,
      ownerDisplayName: json['ownerDisplayName'] as String,
      ownerPhotoUrl: json['ownerPhotoUrl'] as String?,
      sharedLists: (json['sharedLists'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      visibleTo:
          (json['visibleTo'] as List<dynamic>).map((e) => e as String).toList(),
      reactionCount: (json['reactionCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ScheduleImplToJson(_$ScheduleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'startDateTime': instance.startDateTime.toIso8601String(),
      'endDateTime': instance.endDateTime.toIso8601String(),
      'ownerId': instance.ownerId,
      'ownerDisplayName': instance.ownerDisplayName,
      'ownerPhotoUrl': instance.ownerPhotoUrl,
      'sharedLists': instance.sharedLists,
      'visibleTo': instance.visibleTo,
      'reactionCount': instance.reactionCount,
      'commentCount': instance.commentCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
