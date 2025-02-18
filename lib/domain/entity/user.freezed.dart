// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PublicUserModel _$PublicUserModelFromJson(Map<String, dynamic> json) {
  return _PublicUserModel.fromJson(json);
}

/// @nodoc
mixin _$PublicUserModel {
  String get id => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  @UserIdConverter()
  UserId get searchId => throw _privateConstructorUsedError;
  String? get iconUrl => throw _privateConstructorUsedError;
  String? get shortBio => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PublicUserModelCopyWith<PublicUserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PublicUserModelCopyWith<$Res> {
  factory $PublicUserModelCopyWith(
          PublicUserModel value, $Res Function(PublicUserModel) then) =
      _$PublicUserModelCopyWithImpl<$Res, PublicUserModel>;
  @useResult
  $Res call(
      {String id,
      String displayName,
      @UserIdConverter() UserId searchId,
      String? iconUrl,
      String? shortBio});
}

/// @nodoc
class _$PublicUserModelCopyWithImpl<$Res, $Val extends PublicUserModel>
    implements $PublicUserModelCopyWith<$Res> {
  _$PublicUserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? searchId = null,
    Object? iconUrl = freezed,
    Object? shortBio = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      searchId: null == searchId
          ? _value.searchId
          : searchId // ignore: cast_nullable_to_non_nullable
              as UserId,
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
abstract class _$$PublicUserModelImplCopyWith<$Res>
    implements $PublicUserModelCopyWith<$Res> {
  factory _$$PublicUserModelImplCopyWith(_$PublicUserModelImpl value,
          $Res Function(_$PublicUserModelImpl) then) =
      __$$PublicUserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String displayName,
      @UserIdConverter() UserId searchId,
      String? iconUrl,
      String? shortBio});
}

/// @nodoc
class __$$PublicUserModelImplCopyWithImpl<$Res>
    extends _$PublicUserModelCopyWithImpl<$Res, _$PublicUserModelImpl>
    implements _$$PublicUserModelImplCopyWith<$Res> {
  __$$PublicUserModelImplCopyWithImpl(
      _$PublicUserModelImpl _value, $Res Function(_$PublicUserModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? searchId = null,
    Object? iconUrl = freezed,
    Object? shortBio = freezed,
  }) {
    return _then(_$PublicUserModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      searchId: null == searchId
          ? _value.searchId
          : searchId // ignore: cast_nullable_to_non_nullable
              as UserId,
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
@JsonSerializable()
class _$PublicUserModelImpl extends _PublicUserModel {
  const _$PublicUserModelImpl(
      {required this.id,
      required this.displayName,
      @UserIdConverter() required this.searchId,
      this.iconUrl,
      this.shortBio})
      : super._();

  factory _$PublicUserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PublicUserModelImplFromJson(json);

  @override
  final String id;
  @override
  final String displayName;
  @override
  @UserIdConverter()
  final UserId searchId;
  @override
  final String? iconUrl;
  @override
  final String? shortBio;

  @override
  String toString() {
    return 'PublicUserModel(id: $id, displayName: $displayName, searchId: $searchId, iconUrl: $iconUrl, shortBio: $shortBio)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PublicUserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.searchId, searchId) ||
                other.searchId == searchId) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            (identical(other.shortBio, shortBio) ||
                other.shortBio == shortBio));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, displayName, searchId, iconUrl, shortBio);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PublicUserModelImplCopyWith<_$PublicUserModelImpl> get copyWith =>
      __$$PublicUserModelImplCopyWithImpl<_$PublicUserModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PublicUserModelImplToJson(
      this,
    );
  }
}

abstract class _PublicUserModel extends PublicUserModel {
  const factory _PublicUserModel(
      {required final String id,
      required final String displayName,
      @UserIdConverter() required final UserId searchId,
      final String? iconUrl,
      final String? shortBio}) = _$PublicUserModelImpl;
  const _PublicUserModel._() : super._();

  factory _PublicUserModel.fromJson(Map<String, dynamic> json) =
      _$PublicUserModelImpl.fromJson;

  @override
  String get id;
  @override
  String get displayName;
  @override
  @UserIdConverter()
  UserId get searchId;
  @override
  String? get iconUrl;
  @override
  String? get shortBio;
  @override
  @JsonKey(ignore: true)
  _$$PublicUserModelImplCopyWith<_$PublicUserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PrivateUserModel _$PrivateUserModelFromJson(Map<String, dynamic> json) {
  return _PrivateUserModel.fromJson(json);
}

/// @nodoc
mixin _$PrivateUserModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  List<String> get friends => throw _privateConstructorUsedError;
  List<String> get groups => throw _privateConstructorUsedError;
  List<String> get lists => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PrivateUserModelCopyWith<PrivateUserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrivateUserModelCopyWith<$Res> {
  factory $PrivateUserModelCopyWith(
          PrivateUserModel value, $Res Function(PrivateUserModel) then) =
      _$PrivateUserModelCopyWithImpl<$Res, PrivateUserModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      List<String> friends,
      List<String> groups,
      List<String> lists,
      DateTime createdAt});
}

/// @nodoc
class _$PrivateUserModelCopyWithImpl<$Res, $Val extends PrivateUserModel>
    implements $PrivateUserModelCopyWith<$Res> {
  _$PrivateUserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? friends = null,
    Object? groups = null,
    Object? lists = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      friends: null == friends
          ? _value.friends
          : friends // ignore: cast_nullable_to_non_nullable
              as List<String>,
      groups: null == groups
          ? _value.groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<String>,
      lists: null == lists
          ? _value.lists
          : lists // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PrivateUserModelImplCopyWith<$Res>
    implements $PrivateUserModelCopyWith<$Res> {
  factory _$$PrivateUserModelImplCopyWith(_$PrivateUserModelImpl value,
          $Res Function(_$PrivateUserModelImpl) then) =
      __$$PrivateUserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      List<String> friends,
      List<String> groups,
      List<String> lists,
      DateTime createdAt});
}

/// @nodoc
class __$$PrivateUserModelImplCopyWithImpl<$Res>
    extends _$PrivateUserModelCopyWithImpl<$Res, _$PrivateUserModelImpl>
    implements _$$PrivateUserModelImplCopyWith<$Res> {
  __$$PrivateUserModelImplCopyWithImpl(_$PrivateUserModelImpl _value,
      $Res Function(_$PrivateUserModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? friends = null,
    Object? groups = null,
    Object? lists = null,
    Object? createdAt = null,
  }) {
    return _then(_$PrivateUserModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      friends: null == friends
          ? _value._friends
          : friends // ignore: cast_nullable_to_non_nullable
              as List<String>,
      groups: null == groups
          ? _value._groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<String>,
      lists: null == lists
          ? _value._lists
          : lists // ignore: cast_nullable_to_non_nullable
              as List<String>,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PrivateUserModelImpl extends _PrivateUserModel {
  const _$PrivateUserModelImpl(
      {required this.id,
      required this.name,
      required final List<String> friends,
      required final List<String> groups,
      required final List<String> lists,
      required this.createdAt})
      : _friends = friends,
        _groups = groups,
        _lists = lists,
        super._();

  factory _$PrivateUserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrivateUserModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
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
  String toString() {
    return 'PrivateUserModel(id: $id, name: $name, friends: $friends, groups: $groups, lists: $lists, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrivateUserModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._friends, _friends) &&
            const DeepCollectionEquality().equals(other._groups, _groups) &&
            const DeepCollectionEquality().equals(other._lists, _lists) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      const DeepCollectionEquality().hash(_friends),
      const DeepCollectionEquality().hash(_groups),
      const DeepCollectionEquality().hash(_lists),
      createdAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PrivateUserModelImplCopyWith<_$PrivateUserModelImpl> get copyWith =>
      __$$PrivateUserModelImplCopyWithImpl<_$PrivateUserModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PrivateUserModelImplToJson(
      this,
    );
  }
}

abstract class _PrivateUserModel extends PrivateUserModel {
  const factory _PrivateUserModel(
      {required final String id,
      required final String name,
      required final List<String> friends,
      required final List<String> groups,
      required final List<String> lists,
      required final DateTime createdAt}) = _$PrivateUserModelImpl;
  const _PrivateUserModel._() : super._();

  factory _PrivateUserModel.fromJson(Map<String, dynamic> json) =
      _$PrivateUserModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  List<String> get friends;
  @override
  List<String> get groups;
  @override
  List<String> get lists;
  @override
  DateTime get createdAt;
  @override
  @JsonKey(ignore: true)
  _$$PrivateUserModelImplCopyWith<_$PrivateUserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserModel _$UserModelFromJson(Map<String, dynamic> json) {
  return _UserModel.fromJson(json);
}

/// @nodoc
mixin _$UserModel {
  PublicUserModel get publicProfile => throw _privateConstructorUsedError;
  PrivateUserModel get privateProfile => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $UserModelCopyWith<UserModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserModelCopyWith<$Res> {
  factory $UserModelCopyWith(UserModel value, $Res Function(UserModel) then) =
      _$UserModelCopyWithImpl<$Res, UserModel>;
  @useResult
  $Res call({PublicUserModel publicProfile, PrivateUserModel privateProfile});

  $PublicUserModelCopyWith<$Res> get publicProfile;
  $PrivateUserModelCopyWith<$Res> get privateProfile;
}

/// @nodoc
class _$UserModelCopyWithImpl<$Res, $Val extends UserModel>
    implements $UserModelCopyWith<$Res> {
  _$UserModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicProfile = null,
    Object? privateProfile = null,
  }) {
    return _then(_value.copyWith(
      publicProfile: null == publicProfile
          ? _value.publicProfile
          : publicProfile // ignore: cast_nullable_to_non_nullable
              as PublicUserModel,
      privateProfile: null == privateProfile
          ? _value.privateProfile
          : privateProfile // ignore: cast_nullable_to_non_nullable
              as PrivateUserModel,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $PublicUserModelCopyWith<$Res> get publicProfile {
    return $PublicUserModelCopyWith<$Res>(_value.publicProfile, (value) {
      return _then(_value.copyWith(publicProfile: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $PrivateUserModelCopyWith<$Res> get privateProfile {
    return $PrivateUserModelCopyWith<$Res>(_value.privateProfile, (value) {
      return _then(_value.copyWith(privateProfile: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UserModelImplCopyWith<$Res>
    implements $UserModelCopyWith<$Res> {
  factory _$$UserModelImplCopyWith(
          _$UserModelImpl value, $Res Function(_$UserModelImpl) then) =
      __$$UserModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({PublicUserModel publicProfile, PrivateUserModel privateProfile});

  @override
  $PublicUserModelCopyWith<$Res> get publicProfile;
  @override
  $PrivateUserModelCopyWith<$Res> get privateProfile;
}

/// @nodoc
class __$$UserModelImplCopyWithImpl<$Res>
    extends _$UserModelCopyWithImpl<$Res, _$UserModelImpl>
    implements _$$UserModelImplCopyWith<$Res> {
  __$$UserModelImplCopyWithImpl(
      _$UserModelImpl _value, $Res Function(_$UserModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? publicProfile = null,
    Object? privateProfile = null,
  }) {
    return _then(_$UserModelImpl(
      publicProfile: null == publicProfile
          ? _value.publicProfile
          : publicProfile // ignore: cast_nullable_to_non_nullable
              as PublicUserModel,
      privateProfile: null == privateProfile
          ? _value.privateProfile
          : privateProfile // ignore: cast_nullable_to_non_nullable
              as PrivateUserModel,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UserModelImpl extends _UserModel {
  const _$UserModelImpl(
      {required this.publicProfile, required this.privateProfile})
      : super._();

  factory _$UserModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserModelImplFromJson(json);

  @override
  final PublicUserModel publicProfile;
  @override
  final PrivateUserModel privateProfile;

  @override
  String toString() {
    return 'UserModel(publicProfile: $publicProfile, privateProfile: $privateProfile)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserModelImpl &&
            (identical(other.publicProfile, publicProfile) ||
                other.publicProfile == publicProfile) &&
            (identical(other.privateProfile, privateProfile) ||
                other.privateProfile == privateProfile));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, publicProfile, privateProfile);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      __$$UserModelImplCopyWithImpl<_$UserModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserModelImplToJson(
      this,
    );
  }
}

abstract class _UserModel extends UserModel {
  const factory _UserModel(
      {required final PublicUserModel publicProfile,
      required final PrivateUserModel privateProfile}) = _$UserModelImpl;
  const _UserModel._() : super._();

  factory _UserModel.fromJson(Map<String, dynamic> json) =
      _$UserModelImpl.fromJson;

  @override
  PublicUserModel get publicProfile;
  @override
  PrivateUserModel get privateProfile;
  @override
  @JsonKey(ignore: true)
  _$$UserModelImplCopyWith<_$UserModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
