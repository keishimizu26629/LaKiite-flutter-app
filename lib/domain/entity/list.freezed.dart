// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UserList _$UserListFromJson(Map<String, dynamic> json) {
  return _UserList.fromJson(json);
}

/// @nodoc
mixin _$UserList {
  String get id => throw _privateConstructorUsedError;
  String get listName => throw _privateConstructorUsedError;
  String get ownerId => throw _privateConstructorUsedError;
  List<String> get memberIds => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get iconUrl => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserListCopyWith<UserList> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserListCopyWith<$Res> {
  factory $UserListCopyWith(UserList value, $Res Function(UserList) then) =
      _$UserListCopyWithImpl<$Res, UserList>;
  @useResult
  $Res call(
      {String id,
      String listName,
      String ownerId,
      List<String> memberIds,
      DateTime createdAt,
      String? iconUrl,
      String? description});
}

/// @nodoc
class _$UserListCopyWithImpl<$Res, $Val extends UserList>
    implements $UserListCopyWith<$Res> {
  _$UserListCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? listName = null,
    Object? ownerId = null,
    Object? memberIds = null,
    Object? createdAt = null,
    Object? iconUrl = freezed,
    Object? description = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      listName: null == listName
          ? _value.listName
          : listName // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      memberIds: null == memberIds
          ? _value.memberIds
          : memberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      iconUrl: freezed == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserListImplCopyWith<$Res>
    implements $UserListCopyWith<$Res> {
  factory _$$UserListImplCopyWith(
          _$UserListImpl value, $Res Function(_$UserListImpl) then) =
      __$$UserListImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String listName,
      String ownerId,
      List<String> memberIds,
      DateTime createdAt,
      String? iconUrl,
      String? description});
}

/// @nodoc
class __$$UserListImplCopyWithImpl<$Res>
    extends _$UserListCopyWithImpl<$Res, _$UserListImpl>
    implements _$$UserListImplCopyWith<$Res> {
  __$$UserListImplCopyWithImpl(
      _$UserListImpl _value, $Res Function(_$UserListImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? listName = null,
    Object? ownerId = null,
    Object? memberIds = null,
    Object? createdAt = null,
    Object? iconUrl = freezed,
    Object? description = freezed,
  }) {
    return _then(_$UserListImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      listName: null == listName
          ? _value.listName
          : listName // ignore: cast_nullable_to_non_nullable
              as String,
      ownerId: null == ownerId
          ? _value.ownerId
          : ownerId // ignore: cast_nullable_to_non_nullable
              as String,
      memberIds: null == memberIds
          ? _value._memberIds
          : memberIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      iconUrl: freezed == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserListImpl implements _UserList {
  _$UserListImpl(
      {required this.id,
      required this.listName,
      required this.ownerId,
      required final List<String> memberIds,
      required this.createdAt,
      this.iconUrl,
      this.description})
      : _memberIds = memberIds;

  factory _$UserListImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserListImplFromJson(json);

  @override
  final String id;
  @override
  final String listName;
  @override
  final String ownerId;
  final List<String> _memberIds;
  @override
  List<String> get memberIds {
    if (_memberIds is EqualUnmodifiableListView) return _memberIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_memberIds);
  }

  @override
  final DateTime createdAt;
  @override
  final String? iconUrl;
  @override
  final String? description;

  @override
  String toString() {
    return 'UserList(id: $id, listName: $listName, ownerId: $ownerId, memberIds: $memberIds, createdAt: $createdAt, iconUrl: $iconUrl, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserListImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.listName, listName) ||
                other.listName == listName) &&
            (identical(other.ownerId, ownerId) || other.ownerId == ownerId) &&
            const DeepCollectionEquality()
                .equals(other._memberIds, _memberIds) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      listName,
      ownerId,
      const DeepCollectionEquality().hash(_memberIds),
      createdAt,
      iconUrl,
      description);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserListImplCopyWith<_$UserListImpl> get copyWith =>
      __$$UserListImplCopyWithImpl<_$UserListImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserListImplToJson(
      this,
    );
  }
}

abstract class _UserList implements UserList {
  factory _UserList(
      {required final String id,
      required final String listName,
      required final String ownerId,
      required final List<String> memberIds,
      required final DateTime createdAt,
      final String? iconUrl,
      final String? description}) = _$UserListImpl;

  factory _UserList.fromJson(Map<String, dynamic> json) =
      _$UserListImpl.fromJson;

  @override
  String get id;
  @override
  String get listName;
  @override
  String get ownerId;
  @override
  List<String> get memberIds;
  @override
  DateTime get createdAt;
  @override
  String? get iconUrl;
  @override
  String? get description;
  @override
  @JsonKey(ignore: true)
  _$$UserListImplCopyWith<_$UserListImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
