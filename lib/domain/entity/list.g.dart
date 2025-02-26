// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserListImpl _$$UserListImplFromJson(Map<String, dynamic> json) =>
    _$UserListImpl(
      id: json['id'] as String,
      listName: json['listName'] as String,
      ownerId: json['ownerId'] as String,
      memberIds:
          (json['memberIds'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      iconUrl: json['iconUrl'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$$UserListImplToJson(_$UserListImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'listName': instance.listName,
      'ownerId': instance.ownerId,
      'memberIds': instance.memberIds,
      'createdAt': instance.createdAt.toIso8601String(),
      'iconUrl': instance.iconUrl,
      'description': instance.description,
    };
