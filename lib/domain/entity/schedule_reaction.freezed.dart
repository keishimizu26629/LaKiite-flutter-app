// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_reaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ScheduleReaction {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  ReactionType get type => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get userDisplayName => throw _privateConstructorUsedError;
  String? get userPhotoUrl => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ScheduleReactionCopyWith<ScheduleReaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduleReactionCopyWith<$Res> {
  factory $ScheduleReactionCopyWith(
          ScheduleReaction value, $Res Function(ScheduleReaction) then) =
      _$ScheduleReactionCopyWithImpl<$Res, ScheduleReaction>;
  @useResult
  $Res call(
      {String id,
      String userId,
      ReactionType type,
      DateTime createdAt,
      String? userDisplayName,
      String? userPhotoUrl});
}

/// @nodoc
class _$ScheduleReactionCopyWithImpl<$Res, $Val extends ScheduleReaction>
    implements $ScheduleReactionCopyWith<$Res> {
  _$ScheduleReactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? createdAt = null,
    Object? userDisplayName = freezed,
    Object? userPhotoUrl = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ReactionType,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      userDisplayName: freezed == userDisplayName
          ? _value.userDisplayName
          : userDisplayName // ignore: cast_nullable_to_non_nullable
              as String?,
      userPhotoUrl: freezed == userPhotoUrl
          ? _value.userPhotoUrl
          : userPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScheduleReactionImplCopyWith<$Res>
    implements $ScheduleReactionCopyWith<$Res> {
  factory _$$ScheduleReactionImplCopyWith(_$ScheduleReactionImpl value,
          $Res Function(_$ScheduleReactionImpl) then) =
      __$$ScheduleReactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      ReactionType type,
      DateTime createdAt,
      String? userDisplayName,
      String? userPhotoUrl});
}

/// @nodoc
class __$$ScheduleReactionImplCopyWithImpl<$Res>
    extends _$ScheduleReactionCopyWithImpl<$Res, _$ScheduleReactionImpl>
    implements _$$ScheduleReactionImplCopyWith<$Res> {
  __$$ScheduleReactionImplCopyWithImpl(_$ScheduleReactionImpl _value,
      $Res Function(_$ScheduleReactionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? type = null,
    Object? createdAt = null,
    Object? userDisplayName = freezed,
    Object? userPhotoUrl = freezed,
  }) {
    return _then(_$ScheduleReactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ReactionType,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      userDisplayName: freezed == userDisplayName
          ? _value.userDisplayName
          : userDisplayName // ignore: cast_nullable_to_non_nullable
              as String?,
      userPhotoUrl: freezed == userPhotoUrl
          ? _value.userPhotoUrl
          : userPhotoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ScheduleReactionImpl implements _ScheduleReaction {
  const _$ScheduleReactionImpl(
      {required this.id,
      required this.userId,
      required this.type,
      required this.createdAt,
      this.userDisplayName,
      this.userPhotoUrl});

  @override
  final String id;
  @override
  final String userId;
  @override
  final ReactionType type;
  @override
  final DateTime createdAt;
  @override
  final String? userDisplayName;
  @override
  final String? userPhotoUrl;

  @override
  String toString() {
    return 'ScheduleReaction(id: $id, userId: $userId, type: $type, createdAt: $createdAt, userDisplayName: $userDisplayName, userPhotoUrl: $userPhotoUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleReactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.userDisplayName, userDisplayName) ||
                other.userDisplayName == userDisplayName) &&
            (identical(other.userPhotoUrl, userPhotoUrl) ||
                other.userPhotoUrl == userPhotoUrl));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, userId, type, createdAt, userDisplayName, userPhotoUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleReactionImplCopyWith<_$ScheduleReactionImpl> get copyWith =>
      __$$ScheduleReactionImplCopyWithImpl<_$ScheduleReactionImpl>(
          this, _$identity);
}

abstract class _ScheduleReaction implements ScheduleReaction {
  const factory _ScheduleReaction(
      {required final String id,
      required final String userId,
      required final ReactionType type,
      required final DateTime createdAt,
      final String? userDisplayName,
      final String? userPhotoUrl}) = _$ScheduleReactionImpl;

  @override
  String get id;
  @override
  String get userId;
  @override
  ReactionType get type;
  @override
  DateTime get createdAt;
  @override
  String? get userDisplayName;
  @override
  String? get userPhotoUrl;
  @override
  @JsonKey(ignore: true)
  _$$ScheduleReactionImplCopyWith<_$ScheduleReactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
