// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$PublicProfile {
  String get displayName => throw _privateConstructorUsedError;
  String get searchId => throw _privateConstructorUsedError;
  String? get iconUrl => throw _privateConstructorUsedError;
  String? get shortBio => throw _privateConstructorUsedError;

  /// Create a copy of PublicProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PublicProfileCopyWith<PublicProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PublicProfileCopyWith<$Res> {
  factory $PublicProfileCopyWith(
          PublicProfile value, $Res Function(PublicProfile) then) =
      _$PublicProfileCopyWithImpl<$Res, PublicProfile>;
  @useResult
  $Res call(
      {String displayName, String searchId, String? iconUrl, String? shortBio});
}

/// @nodoc
class _$PublicProfileCopyWithImpl<$Res, $Val extends PublicProfile>
    implements $PublicProfileCopyWith<$Res> {
  _$PublicProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PublicProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? displayName = null,
    Object? searchId = null,
    Object? iconUrl = freezed,
    Object? shortBio = freezed,
  }) {
    return _then(_value.copyWith(
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      searchId: null == searchId
          ? _value.searchId
          : searchId // ignore: cast_nullable_to_non_nullable
              as String,
      iconUrl: freezed == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      shortBio: freezed == shortBio
          ? _value.shortBio
          : shortBio // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PublicProfileImplCopyWith<$Res>
    implements $PublicProfileCopyWith<$Res> {
  factory _$$PublicProfileImplCopyWith(
          _$PublicProfileImpl value, $Res Function(_$PublicProfileImpl) then) =
      __$$PublicProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String displayName, String searchId, String? iconUrl, String? shortBio});
}

/// @nodoc
class __$$PublicProfileImplCopyWithImpl<$Res>
    extends _$PublicProfileCopyWithImpl<$Res, _$PublicProfileImpl>
    implements _$$PublicProfileImplCopyWith<$Res> {
  __$$PublicProfileImplCopyWithImpl(
      _$PublicProfileImpl _value, $Res Function(_$PublicProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of PublicProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? displayName = null,
    Object? searchId = null,
    Object? iconUrl = freezed,
    Object? shortBio = freezed,
  }) {
    return _then(_$PublicProfileImpl(
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      searchId: null == searchId
          ? _value.searchId
          : searchId // ignore: cast_nullable_to_non_nullable
              as String,
      iconUrl: freezed == iconUrl
          ? _value.iconUrl
          : iconUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      shortBio: freezed == shortBio
          ? _value.shortBio
          : shortBio // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$PublicProfileImpl implements _PublicProfile {
  const _$PublicProfileImpl(
      {required this.displayName,
      required this.searchId,
      this.iconUrl,
      this.shortBio});

  @override
  final String displayName;
  @override
  final String searchId;
  @override
  final String? iconUrl;
  @override
  final String? shortBio;

  @override
  String toString() {
    return 'PublicProfile(displayName: $displayName, searchId: $searchId, iconUrl: $iconUrl, shortBio: $shortBio)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PublicProfileImpl &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.searchId, searchId) ||
                other.searchId == searchId) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            (identical(other.shortBio, shortBio) ||
                other.shortBio == shortBio));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, displayName, searchId, iconUrl, shortBio);

  /// Create a copy of PublicProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PublicProfileImplCopyWith<_$PublicProfileImpl> get copyWith =>
      __$$PublicProfileImplCopyWithImpl<_$PublicProfileImpl>(this, _$identity);
}

abstract class _PublicProfile implements PublicProfile {
  const factory _PublicProfile(
      {required final String displayName,
      required final String searchId,
      final String? iconUrl,
      final String? shortBio}) = _$PublicProfileImpl;

  @override
  String get displayName;
  @override
  String get searchId;
  @override
  String? get iconUrl;
  @override
  String? get shortBio;

  /// Create a copy of PublicProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PublicProfileImplCopyWith<_$PublicProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$PrivateProfile {
  String get name => throw _privateConstructorUsedError;
  List<String> get lists => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  String? get fcmToken => throw _privateConstructorUsedError;

  /// Create a copy of PrivateProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrivateProfileCopyWith<PrivateProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrivateProfileCopyWith<$Res> {
  factory $PrivateProfileCopyWith(
          PrivateProfile value, $Res Function(PrivateProfile) then) =
      _$PrivateProfileCopyWithImpl<$Res, PrivateProfile>;
  @useResult
  $Res call(
      {String name, List<String> lists, DateTime createdAt, String? fcmToken});
}

/// @nodoc
class _$PrivateProfileCopyWithImpl<$Res, $Val extends PrivateProfile>
    implements $PrivateProfileCopyWith<$Res> {
  _$PrivateProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrivateProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? lists = null,
    Object? createdAt = null,
    Object? fcmToken = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      lists: null == lists
          ? _value.lists
          : lists // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      fcmToken: freezed == fcmToken
          ? _value.fcmToken
          : fcmToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PrivateProfileImplCopyWith<$Res>
    implements $PrivateProfileCopyWith<$Res> {
  factory _$$PrivateProfileImplCopyWith(_$PrivateProfileImpl value,
          $Res Function(_$PrivateProfileImpl) then) =
      __$$PrivateProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name, List<String> lists, DateTime createdAt, String? fcmToken});
}

/// @nodoc
class __$$PrivateProfileImplCopyWithImpl<$Res>
    extends _$PrivateProfileCopyWithImpl<$Res, _$PrivateProfileImpl>
    implements _$$PrivateProfileImplCopyWith<$Res> {
  __$$PrivateProfileImplCopyWithImpl(
      _$PrivateProfileImpl _value, $Res Function(_$PrivateProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of PrivateProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? lists = null,
    Object? createdAt = null,
    Object? fcmToken = freezed,
  }) {
    return _then(_$PrivateProfileImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      lists: null == lists
          ? _value._lists
          : lists // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      fcmToken: freezed == fcmToken
          ? _value.fcmToken
          : fcmToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$PrivateProfileImpl implements _PrivateProfile {
  const _$PrivateProfileImpl(
      {required this.name,
      required final List<String> lists,
      required this.createdAt,
      this.fcmToken})
      : _lists = lists;

  @override
  final String name;
  final List<String> _lists;
  @override
  List<String> get lists {
    if (_lists is EqualUnmodifiableListView) return _lists;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_lists);
  }

  @override
  final DateTime createdAt;
  @override
  final String? fcmToken;

  @override
  String toString() {
    return 'PrivateProfile(name: $name, lists: $lists, createdAt: $createdAt, fcmToken: $fcmToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrivateProfileImpl &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._lists, _lists) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.fcmToken, fcmToken) ||
                other.fcmToken == fcmToken));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name,
      const DeepCollectionEquality().hash(_lists), createdAt, fcmToken);

  /// Create a copy of PrivateProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrivateProfileImplCopyWith<_$PrivateProfileImpl> get copyWith =>
      __$$PrivateProfileImplCopyWithImpl<_$PrivateProfileImpl>(
          this, _$identity);
}

abstract class _PrivateProfile implements PrivateProfile {
  const factory _PrivateProfile(
      {required final String name,
      required final List<String> lists,
      required final DateTime createdAt,
      final String? fcmToken}) = _$PrivateProfileImpl;

  @override
  String get name;
  @override
  List<String> get lists;
  @override
  DateTime get createdAt;
  @override
  String? get fcmToken;

  /// Create a copy of PrivateProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrivateProfileImplCopyWith<_$PrivateProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$UserProfile {
  String get id => throw _privateConstructorUsedError;
  PublicProfile get publicProfile => throw _privateConstructorUsedError;
  PrivateProfile get privateProfile => throw _privateConstructorUsedError;
  List<String> get friends => throw _privateConstructorUsedError;
  List<String> get groups => throw _privateConstructorUsedError;
  String? get fcmToken => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
          UserProfile value, $Res Function(UserProfile) then) =
      _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call(
      {String id,
      PublicProfile publicProfile,
      PrivateProfile privateProfile,
      List<String> friends,
      List<String> groups,
      String? fcmToken});

  $PublicProfileCopyWith<$Res> get publicProfile;
  $PrivateProfileCopyWith<$Res> get privateProfile;
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? publicProfile = null,
    Object? privateProfile = null,
    Object? friends = null,
    Object? groups = null,
    Object? fcmToken = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      publicProfile: null == publicProfile
          ? _value.publicProfile
          : publicProfile // ignore: cast_nullable_to_non_nullable
              as PublicProfile,
      privateProfile: null == privateProfile
          ? _value.privateProfile
          : privateProfile // ignore: cast_nullable_to_non_nullable
              as PrivateProfile,
      friends: null == friends
          ? _value.friends
          : friends // ignore: cast_nullable_to_non_nullable
              as List<String>,
      groups: null == groups
          ? _value.groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<String>,
      fcmToken: freezed == fcmToken
          ? _value.fcmToken
          : fcmToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PublicProfileCopyWith<$Res> get publicProfile {
    return $PublicProfileCopyWith<$Res>(_value.publicProfile, (value) {
      return _then(_value.copyWith(publicProfile: value) as $Val);
    });
  }

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PrivateProfileCopyWith<$Res> get privateProfile {
    return $PrivateProfileCopyWith<$Res>(_value.privateProfile, (value) {
      return _then(_value.copyWith(privateProfile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
          _$UserProfileImpl value, $Res Function(_$UserProfileImpl) then) =
      __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      PublicProfile publicProfile,
      PrivateProfile privateProfile,
      List<String> friends,
      List<String> groups,
      String? fcmToken});

  @override
  $PublicProfileCopyWith<$Res> get publicProfile;
  @override
  $PrivateProfileCopyWith<$Res> get privateProfile;
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
      _$UserProfileImpl _value, $Res Function(_$UserProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? publicProfile = null,
    Object? privateProfile = null,
    Object? friends = null,
    Object? groups = null,
    Object? fcmToken = freezed,
  }) {
    return _then(_$UserProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      publicProfile: null == publicProfile
          ? _value.publicProfile
          : publicProfile // ignore: cast_nullable_to_non_nullable
              as PublicProfile,
      privateProfile: null == privateProfile
          ? _value.privateProfile
          : privateProfile // ignore: cast_nullable_to_non_nullable
              as PrivateProfile,
      friends: null == friends
          ? _value._friends
          : friends // ignore: cast_nullable_to_non_nullable
              as List<String>,
      groups: null == groups
          ? _value._groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<String>,
      fcmToken: freezed == fcmToken
          ? _value.fcmToken
          : fcmToken // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl(
      {required this.id,
      required this.publicProfile,
      required this.privateProfile,
      required final List<String> friends,
      required final List<String> groups,
      this.fcmToken})
      : _friends = friends,
        _groups = groups;

  @override
  final String id;
  @override
  final PublicProfile publicProfile;
  @override
  final PrivateProfile privateProfile;
  final List<String> _friends;
  @override
  List<String> get friends {
    if (_friends is EqualUnmodifiableListView) return _friends;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_friends);
  }

  final List<String> _groups;
  @override
  List<String> get groups {
    if (_groups is EqualUnmodifiableListView) return _groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_groups);
  }

  @override
  final String? fcmToken;

  @override
  String toString() {
    return 'UserProfile(id: $id, publicProfile: $publicProfile, privateProfile: $privateProfile, friends: $friends, groups: $groups, fcmToken: $fcmToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.publicProfile, publicProfile) ||
                other.publicProfile == publicProfile) &&
            (identical(other.privateProfile, privateProfile) ||
                other.privateProfile == privateProfile) &&
            const DeepCollectionEquality().equals(other._friends, _friends) &&
            const DeepCollectionEquality().equals(other._groups, _groups) &&
            (identical(other.fcmToken, fcmToken) ||
                other.fcmToken == fcmToken));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      publicProfile,
      privateProfile,
      const DeepCollectionEquality().hash(_friends),
      const DeepCollectionEquality().hash(_groups),
      fcmToken);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile(
      {required final String id,
      required final PublicProfile publicProfile,
      required final PrivateProfile privateProfile,
      required final List<String> friends,
      required final List<String> groups,
      final String? fcmToken}) = _$UserProfileImpl;

  @override
  String get id;
  @override
  PublicProfile get publicProfile;
  @override
  PrivateProfile get privateProfile;
  @override
  List<String> get friends;
  @override
  List<String> get groups;
  @override
  String? get fcmToken;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
