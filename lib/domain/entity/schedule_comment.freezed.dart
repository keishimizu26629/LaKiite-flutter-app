// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ScheduleComment _$ScheduleCommentFromJson(Map<String, dynamic> json) {
  return _ScheduleComment.fromJson(json);
}

/// @nodoc
mixin _$ScheduleComment {
  String get id => throw _privateConstructorUsedError;
  String get scheduleId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get userDisplayName => throw _privateConstructorUsedError;
  String? get userPhotoUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ScheduleCommentCopyWith<ScheduleComment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduleCommentCopyWith<$Res> {
  factory $ScheduleCommentCopyWith(
          ScheduleComment value, $Res Function(ScheduleComment) then) =
      _$ScheduleCommentCopyWithImpl<$Res, ScheduleComment>;
  @useResult
  $Res call(
      {String id,
      String scheduleId,
      String userId,
      String content,
      DateTime createdAt,
      String? userDisplayName,
      String? userPhotoUrl});
}

/// @nodoc
class _$ScheduleCommentCopyWithImpl<$Res, $Val extends ScheduleComment>
    implements $ScheduleCommentCopyWith<$Res> {
  _$ScheduleCommentCopyWithImpl(this._value, this._then);

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
    Object? content = null,
    Object? createdAt = null,
    Object? userDisplayName = freezed,
    Object? userPhotoUrl = freezed,
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
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
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
abstract class _$$ScheduleCommentImplCopyWith<$Res>
    implements $ScheduleCommentCopyWith<$Res> {
  factory _$$ScheduleCommentImplCopyWith(_$ScheduleCommentImpl value,
          $Res Function(_$ScheduleCommentImpl) then) =
      __$$ScheduleCommentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String scheduleId,
      String userId,
      String content,
      DateTime createdAt,
      String? userDisplayName,
      String? userPhotoUrl});
}

/// @nodoc
class __$$ScheduleCommentImplCopyWithImpl<$Res>
    extends _$ScheduleCommentCopyWithImpl<$Res, _$ScheduleCommentImpl>
    implements _$$ScheduleCommentImplCopyWith<$Res> {
  __$$ScheduleCommentImplCopyWithImpl(
      _$ScheduleCommentImpl _value, $Res Function(_$ScheduleCommentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? scheduleId = null,
    Object? userId = null,
    Object? content = null,
    Object? createdAt = null,
    Object? userDisplayName = freezed,
    Object? userPhotoUrl = freezed,
  }) {
    return _then(_$ScheduleCommentImpl(
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
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
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
@JsonSerializable()
class _$ScheduleCommentImpl implements _ScheduleComment {
  const _$ScheduleCommentImpl(
      {required this.id,
      required this.scheduleId,
      required this.userId,
      required this.content,
      required this.createdAt,
      this.userDisplayName,
      this.userPhotoUrl});

  factory _$ScheduleCommentImpl.fromJson(Map<String, dynamic> json) =>
      _$$ScheduleCommentImplFromJson(json);

  @override
  final String id;
  @override
  final String scheduleId;
  @override
  final String userId;
  @override
  final String content;
  @override
  final DateTime createdAt;
  @override
  final String? userDisplayName;
  @override
  final String? userPhotoUrl;

  @override
  String toString() {
    return 'ScheduleComment(id: $id, scheduleId: $scheduleId, userId: $userId, content: $content, createdAt: $createdAt, userDisplayName: $userDisplayName, userPhotoUrl: $userPhotoUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleCommentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.scheduleId, scheduleId) ||
                other.scheduleId == scheduleId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.userDisplayName, userDisplayName) ||
                other.userDisplayName == userDisplayName) &&
            (identical(other.userPhotoUrl, userPhotoUrl) ||
                other.userPhotoUrl == userPhotoUrl));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, scheduleId, userId, content,
      createdAt, userDisplayName, userPhotoUrl);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleCommentImplCopyWith<_$ScheduleCommentImpl> get copyWith =>
      __$$ScheduleCommentImplCopyWithImpl<_$ScheduleCommentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ScheduleCommentImplToJson(
      this,
    );
  }
}

abstract class _ScheduleComment implements ScheduleComment {
  const factory _ScheduleComment(
      {required final String id,
      required final String scheduleId,
      required final String userId,
      required final String content,
      required final DateTime createdAt,
      final String? userDisplayName,
      final String? userPhotoUrl}) = _$ScheduleCommentImpl;

  factory _ScheduleComment.fromJson(Map<String, dynamic> json) =
      _$ScheduleCommentImpl.fromJson;

  @override
  String get id;
  @override
  String get scheduleId;
  @override
  String get userId;
  @override
  String get content;
  @override
  DateTime get createdAt;
  @override
  String? get userDisplayName;
  @override
  String? get userPhotoUrl;
  @override
  @JsonKey(ignore: true)
  _$$ScheduleCommentImplCopyWith<_$ScheduleCommentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
