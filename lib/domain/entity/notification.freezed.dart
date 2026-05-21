// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Notification {
  String get id => throw _privateConstructorUsedError;
  NotificationType get type => throw _privateConstructorUsedError;
  String get sendUserId => throw _privateConstructorUsedError;
  String get receiveUserId => throw _privateConstructorUsedError;
  String? get sendUserDisplayName => throw _privateConstructorUsedError;
  String? get receiveUserDisplayName => throw _privateConstructorUsedError;
  NotificationStatus get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  int get rejectionCount => throw _privateConstructorUsedError;
  bool get isRead => throw _privateConstructorUsedError;
  String? get groupId => throw _privateConstructorUsedError;
  String? get relatedItemId => throw _privateConstructorUsedError;
  String? get interactionId => throw _privateConstructorUsedError;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NotificationCopyWith<Notification> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NotificationCopyWith<$Res> {
  factory $NotificationCopyWith(
          Notification value, $Res Function(Notification) then) =
      _$NotificationCopyWithImpl<$Res, Notification>;
  @useResult
  $Res call(
      {String id,
      NotificationType type,
      String sendUserId,
      String receiveUserId,
      String? sendUserDisplayName,
      String? receiveUserDisplayName,
      NotificationStatus status,
      DateTime createdAt,
      DateTime updatedAt,
      int rejectionCount,
      bool isRead,
      String? groupId,
      String? relatedItemId,
      String? interactionId});
}

/// @nodoc
class _$NotificationCopyWithImpl<$Res, $Val extends Notification>
    implements $NotificationCopyWith<$Res> {
  _$NotificationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? sendUserId = null,
    Object? receiveUserId = null,
    Object? sendUserDisplayName = freezed,
    Object? receiveUserDisplayName = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? rejectionCount = null,
    Object? isRead = null,
    Object? groupId = freezed,
    Object? relatedItemId = freezed,
    Object? interactionId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      sendUserId: null == sendUserId
          ? _value.sendUserId
          : sendUserId // ignore: cast_nullable_to_non_nullable
              as String,
      receiveUserId: null == receiveUserId
          ? _value.receiveUserId
          : receiveUserId // ignore: cast_nullable_to_non_nullable
              as String,
      sendUserDisplayName: freezed == sendUserDisplayName
          ? _value.sendUserDisplayName
          : sendUserDisplayName // ignore: cast_nullable_to_non_nullable
              as String?,
      receiveUserDisplayName: freezed == receiveUserDisplayName
          ? _value.receiveUserDisplayName
          : receiveUserDisplayName // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as NotificationStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      rejectionCount: null == rejectionCount
          ? _value.rejectionCount
          : rejectionCount // ignore: cast_nullable_to_non_nullable
              as int,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      relatedItemId: freezed == relatedItemId
          ? _value.relatedItemId
          : relatedItemId // ignore: cast_nullable_to_non_nullable
              as String?,
      interactionId: freezed == interactionId
          ? _value.interactionId
          : interactionId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NotificationImplCopyWith<$Res>
    implements $NotificationCopyWith<$Res> {
  factory _$$NotificationImplCopyWith(
          _$NotificationImpl value, $Res Function(_$NotificationImpl) then) =
      __$$NotificationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      NotificationType type,
      String sendUserId,
      String receiveUserId,
      String? sendUserDisplayName,
      String? receiveUserDisplayName,
      NotificationStatus status,
      DateTime createdAt,
      DateTime updatedAt,
      int rejectionCount,
      bool isRead,
      String? groupId,
      String? relatedItemId,
      String? interactionId});
}

/// @nodoc
class __$$NotificationImplCopyWithImpl<$Res>
    extends _$NotificationCopyWithImpl<$Res, _$NotificationImpl>
    implements _$$NotificationImplCopyWith<$Res> {
  __$$NotificationImplCopyWithImpl(
      _$NotificationImpl _value, $Res Function(_$NotificationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? sendUserId = null,
    Object? receiveUserId = null,
    Object? sendUserDisplayName = freezed,
    Object? receiveUserDisplayName = freezed,
    Object? status = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? rejectionCount = null,
    Object? isRead = null,
    Object? groupId = freezed,
    Object? relatedItemId = freezed,
    Object? interactionId = freezed,
  }) {
    return _then(_$NotificationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as NotificationType,
      sendUserId: null == sendUserId
          ? _value.sendUserId
          : sendUserId // ignore: cast_nullable_to_non_nullable
              as String,
      receiveUserId: null == receiveUserId
          ? _value.receiveUserId
          : receiveUserId // ignore: cast_nullable_to_non_nullable
              as String,
      sendUserDisplayName: freezed == sendUserDisplayName
          ? _value.sendUserDisplayName
          : sendUserDisplayName // ignore: cast_nullable_to_non_nullable
              as String?,
      receiveUserDisplayName: freezed == receiveUserDisplayName
          ? _value.receiveUserDisplayName
          : receiveUserDisplayName // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as NotificationStatus,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      rejectionCount: null == rejectionCount
          ? _value.rejectionCount
          : rejectionCount // ignore: cast_nullable_to_non_nullable
              as int,
      isRead: null == isRead
          ? _value.isRead
          : isRead // ignore: cast_nullable_to_non_nullable
              as bool,
      groupId: freezed == groupId
          ? _value.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as String?,
      relatedItemId: freezed == relatedItemId
          ? _value.relatedItemId
          : relatedItemId // ignore: cast_nullable_to_non_nullable
              as String?,
      interactionId: freezed == interactionId
          ? _value.interactionId
          : interactionId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$NotificationImpl implements _Notification {
  const _$NotificationImpl(
      {required this.id,
      required this.type,
      required this.sendUserId,
      required this.receiveUserId,
      this.sendUserDisplayName,
      this.receiveUserDisplayName,
      required this.status,
      required this.createdAt,
      required this.updatedAt,
      this.rejectionCount = 0,
      this.isRead = false,
      this.groupId,
      this.relatedItemId,
      this.interactionId});

  @override
  final String id;
  @override
  final NotificationType type;
  @override
  final String sendUserId;
  @override
  final String receiveUserId;
  @override
  final String? sendUserDisplayName;
  @override
  final String? receiveUserDisplayName;
  @override
  final NotificationStatus status;
  @override
  final DateTime createdAt;
  @override
  final DateTime updatedAt;
  @override
  @JsonKey()
  final int rejectionCount;
  @override
  @JsonKey()
  final bool isRead;
  @override
  final String? groupId;
  @override
  final String? relatedItemId;
  @override
  final String? interactionId;

  @override
  String toString() {
    return 'Notification(id: $id, type: $type, sendUserId: $sendUserId, receiveUserId: $receiveUserId, sendUserDisplayName: $sendUserDisplayName, receiveUserDisplayName: $receiveUserDisplayName, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, rejectionCount: $rejectionCount, isRead: $isRead, groupId: $groupId, relatedItemId: $relatedItemId, interactionId: $interactionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NotificationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.sendUserId, sendUserId) ||
                other.sendUserId == sendUserId) &&
            (identical(other.receiveUserId, receiveUserId) ||
                other.receiveUserId == receiveUserId) &&
            (identical(other.sendUserDisplayName, sendUserDisplayName) ||
                other.sendUserDisplayName == sendUserDisplayName) &&
            (identical(other.receiveUserDisplayName, receiveUserDisplayName) ||
                other.receiveUserDisplayName == receiveUserDisplayName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.rejectionCount, rejectionCount) ||
                other.rejectionCount == rejectionCount) &&
            (identical(other.isRead, isRead) || other.isRead == isRead) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.relatedItemId, relatedItemId) ||
                other.relatedItemId == relatedItemId) &&
            (identical(other.interactionId, interactionId) ||
                other.interactionId == interactionId));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      sendUserId,
      receiveUserId,
      sendUserDisplayName,
      receiveUserDisplayName,
      status,
      createdAt,
      updatedAt,
      rejectionCount,
      isRead,
      groupId,
      relatedItemId,
      interactionId);

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      __$$NotificationImplCopyWithImpl<_$NotificationImpl>(this, _$identity);
}

abstract class _Notification implements Notification {
  const factory _Notification(
      {required final String id,
      required final NotificationType type,
      required final String sendUserId,
      required final String receiveUserId,
      final String? sendUserDisplayName,
      final String? receiveUserDisplayName,
      required final NotificationStatus status,
      required final DateTime createdAt,
      required final DateTime updatedAt,
      final int rejectionCount,
      final bool isRead,
      final String? groupId,
      final String? relatedItemId,
      final String? interactionId}) = _$NotificationImpl;

  @override
  String get id;
  @override
  NotificationType get type;
  @override
  String get sendUserId;
  @override
  String get receiveUserId;
  @override
  String? get sendUserDisplayName;
  @override
  String? get receiveUserDisplayName;
  @override
  NotificationStatus get status;
  @override
  DateTime get createdAt;
  @override
  DateTime get updatedAt;
  @override
  int get rejectionCount;
  @override
  bool get isRead;
  @override
  String? get groupId;
  @override
  String? get relatedItemId;
  @override
  String? get interactionId;

  /// Create a copy of Notification
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NotificationImplCopyWith<_$NotificationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
