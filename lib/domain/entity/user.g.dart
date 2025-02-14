// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PublicUserModelImpl _$$PublicUserModelImplFromJson(
        Map<String, dynamic> json) =>
    _$PublicUserModelImpl(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      searchId: const UserIdConverter().fromJson(json['searchId'] as String),
      iconUrl: json['iconUrl'] as String?,
    );

Map<String, dynamic> _$$PublicUserModelImplToJson(
        _$PublicUserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'searchId': const UserIdConverter().toJson(instance.searchId),
      'iconUrl': instance.iconUrl,
    };

_$PrivateUserModelImpl _$$PrivateUserModelImplFromJson(
        Map<String, dynamic> json) =>
    _$PrivateUserModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      friends:
          (json['friends'] as List<dynamic>).map((e) => e as String).toList(),
      groups:
          (json['groups'] as List<dynamic>).map((e) => e as String).toList(),
      lists: (json['lists'] as List<dynamic>).map((e) => e as String).toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$PrivateUserModelImplToJson(
        _$PrivateUserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'friends': instance.friends,
      'groups': instance.groups,
      'lists': instance.lists,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      publicProfile: PublicUserModel.fromJson(
          json['publicProfile'] as Map<String, dynamic>),
      privateProfile: PrivateUserModel.fromJson(
          json['privateProfile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'publicProfile': instance.publicProfile,
      'privateProfile': instance.privateProfile,
    };
