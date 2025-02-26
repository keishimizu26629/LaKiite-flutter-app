// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Reaction _$ReactionFromJson(Map<String, dynamic> json) {
  return _Reaction.fromJson(json);
}

/// @nodoc
mixin _$Reaction {
  String get id => throw _privateConstructorUsedError;
  String get scheduleId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get userDisplayName => throw _privateConstructorUsedError;
  String? get userPhotoUrl => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ReactionCopyWith<Reaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReactionCopyWith<$Res> {
  factory $ReactionCopyWith(Reaction value, $Res Function(Reaction) then) =
      _$ReactionCopyWithImpl<$Res, Reaction>;
  @useResult
  $Res call(
      {String id,
      String scheduleId,
      String userId,
      String type,
      String userDisplayName,
      String? userPhotoUrl,
      @TimestampConverter() DateTime createdAt});
}

/// @nodoc
class _$ReactionCopyWithImpl<$Res, $Val extends Reaction>
    implements $ReactionCopyWith<$Res> {
  _$ReactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? scheduleId = null,
    Object? userId = null,
    Object? type = null,
    Object? userDisplayName = null,
    Object? userPhotoUrl = freezed,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      scheduleId: null == scheduleId
          ? _value.scheduleId
          : scheduleId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      userDisplayName: null == userDisplayName
          ? _value.userDisplayName
          : userDisplayName // ignore: cast_nullable_to_non_nullable
              as String,
      userPhotoUrl: freezed == userPhotoUrl
          ? _value.userPhotoUrl
          : userPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReactionImplCopyWith<$Res>
    implements $ReactionCopyWith<$Res> {
  factory _$$ReactionImplCopyWith(
          _$ReactionImpl value, $Res Function(_$ReactionImpl) then) =
      __$$ReactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String scheduleId,
      String userId,
      String type,
      String userDisplayName,
      String? userPhotoUrl,
      @TimestampConverter() DateTime createdAt});
}

/// @nodoc
class __$$ReactionImplCopyWithImpl<$Res>
    extends _$ReactionCopyWithImpl<$Res, _$ReactionImpl>
    implements _$$ReactionImplCopyWith<$Res> {
  __$$ReactionImplCopyWithImpl(
      _$ReactionImpl _value, $Res Function(_$ReactionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? scheduleId = null,
    Object? userId = null,
    Object? type = null,
    Object? userDisplayName = null,
    Object? userPhotoUrl = freezed,
    Object? createdAt = null,
  }) {
    return _then(_$ReactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      scheduleId: null == scheduleId
          ? _value.scheduleId
          : scheduleId // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      userDisplayName: null == userDisplayName
          ? _value.userDisplayName
          : userDisplayName // ignore: cast_nullable_to_non_nullable
              as String,
      userPhotoUrl: freezed == userPhotoUrl
          ? _value.userPhotoUrl
          : userPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReactionImpl implements _Reaction {
  const _$ReactionImpl(
      {required this.id,
      required this.scheduleId,
      required this.userId,
      required this.type,
      required this.userDisplayName,
      this.userPhotoUrl,
      @TimestampConverter() required this.createdAt});

  factory _$ReactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReactionImplFromJson(json);

  @override
  final String id;
  @override
  final String scheduleId;
  @override
  final String userId;
  @override
  final String type;
  @override
  final String userDisplayName;
  @override
  final String? userPhotoUrl;
  @override
  @TimestampConverter()
  final DateTime createdAt;

  @override
  String toString() {
    return 'Reaction(id: $id, scheduleId: $scheduleId, userId: $userId, type: $type, userDisplayName: $userDisplayName, userPhotoUrl: $userPhotoUrl, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.scheduleId, scheduleId) ||
                other.scheduleId == scheduleId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.userDisplayName, userDisplayName) ||
                other.userDisplayName == userDisplayName) &&
            (identical(other.userPhotoUrl, userPhotoUrl) ||
                other.userPhotoUrl == userPhotoUrl) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, scheduleId, userId, type,
      userDisplayName, userPhotoUrl, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReactionImplCopyWith<_$ReactionImpl> get copyWith =>
      __$$ReactionImplCopyWithImpl<_$ReactionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReactionImplToJson(
      this,
    );
  }
}

abstract class _Reaction implements Reaction {
  const factory _Reaction(
          {required final String id,
          required final String scheduleId,
          required final String userId,
          required final String type,
          required final String userDisplayName,
          final String? userPhotoUrl,
          @TimestampConverter() required final DateTime createdAt}) =
      _$ReactionImpl;

  factory _Reaction.fromJson(Map<String, dynamic> json) =
      _$ReactionImpl.fromJson;

  @override
  String get id;
  @override
  String get scheduleId;
  @override
  String get userId;
  @override
  String get type;
  @override
  String get userDisplayName;
  @override
  String? get userPhotoUrl;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ReactionImplCopyWith<_$ReactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
