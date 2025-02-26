// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_like.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScheduleLike _$ScheduleLikeFromJson(Map<String, dynamic> json) {
  return _ScheduleLike.fromJson(json);
}

/// @nodoc
mixin _$ScheduleLike {
  String get id => throw _privateConstructorUsedError;
  String get scheduleId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ScheduleLikeCopyWith<ScheduleLike> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduleLikeCopyWith<$Res> {
  factory $ScheduleLikeCopyWith(
          ScheduleLike value, $Res Function(ScheduleLike) then) =
      _$ScheduleLikeCopyWithImpl<$Res, ScheduleLike>;
  @useResult
  $Res call({String id, String scheduleId, String userId, DateTime createdAt});
}

/// @nodoc
class _$ScheduleLikeCopyWithImpl<$Res, $Val extends ScheduleLike>
    implements $ScheduleLikeCopyWith<$Res> {
  _$ScheduleLikeCopyWithImpl(this._value, this._then);

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
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScheduleLikeImplCopyWith<$Res>
    implements $ScheduleLikeCopyWith<$Res> {
  factory _$$ScheduleLikeImplCopyWith(
          _$ScheduleLikeImpl value, $Res Function(_$ScheduleLikeImpl) then) =
      __$$ScheduleLikeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String scheduleId, String userId, DateTime createdAt});
}

/// @nodoc
class __$$ScheduleLikeImplCopyWithImpl<$Res>
    extends _$ScheduleLikeCopyWithImpl<$Res, _$ScheduleLikeImpl>
    implements _$$ScheduleLikeImplCopyWith<$Res> {
  __$$ScheduleLikeImplCopyWithImpl(
      _$ScheduleLikeImpl _value, $Res Function(_$ScheduleLikeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? scheduleId = null,
    Object? userId = null,
    Object? createdAt = null,
  }) {
    return _then(_$ScheduleLikeImpl(
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
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ScheduleLikeImpl implements _ScheduleLike {
  const _$ScheduleLikeImpl(
      {required this.id,
      required this.scheduleId,
      required this.userId,
      required this.createdAt});

  factory _$ScheduleLikeImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScheduleLikeImplFromJson(json);

  @override
  final String id;
  @override
  final String scheduleId;
  @override
  final String userId;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'ScheduleLike(id: $id, scheduleId: $scheduleId, userId: $userId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleLikeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.scheduleId, scheduleId) ||
                other.scheduleId == scheduleId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, scheduleId, userId, createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleLikeImplCopyWith<_$ScheduleLikeImpl> get copyWith =>
      __$$ScheduleLikeImplCopyWithImpl<_$ScheduleLikeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScheduleLikeImplToJson(
      this,
    );
  }
}

abstract class _ScheduleLike implements ScheduleLike {
  const factory _ScheduleLike(
      {required final String id,
      required final String scheduleId,
      required final String userId,
      required final DateTime createdAt}) = _$ScheduleLikeImpl;

  factory _ScheduleLike.fromJson(Map<String, dynamic> json) =
      _$ScheduleLikeImpl.fromJson;

  @override
  String get id;
  @override
  String get scheduleId;
  @override
  String get userId;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$ScheduleLikeImplCopyWith<_$ScheduleLikeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
