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
      dateTime: DateTime.parse(json['dateTime'] as String),
      ownerId: json['ownerId'] as String,
      sharedLists: (json['sharedLists'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      visibleTo:
          (json['visibleTo'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ScheduleImplToJson(_$ScheduleImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'dateTime': instance.dateTime.toIso8601String(),
      'ownerId': instance.ownerId,
      'sharedLists': instance.sharedLists,
      'visibleTo': instance.visibleTo,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
