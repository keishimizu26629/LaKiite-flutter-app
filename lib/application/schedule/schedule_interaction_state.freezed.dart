// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_interaction_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ScheduleInteractionState {
  List<ScheduleReaction> get reactions => throw _privateConstructorUsedError;
  List<ScheduleComment> get comments => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ScheduleInteractionStateCopyWith<ScheduleInteractionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ScheduleInteractionStateCopyWith<$Res> {
  factory $ScheduleInteractionStateCopyWith(ScheduleInteractionState value,
          $Res Function(ScheduleInteractionState) then) =
      _$ScheduleInteractionStateCopyWithImpl<$Res, ScheduleInteractionState>;
  @useResult
  $Res call(
      {List<ScheduleReaction> reactions,
      List<ScheduleComment> comments,
      bool isLoading,
      String? error});
}

/// @nodoc
class _$ScheduleInteractionStateCopyWithImpl<$Res,
        $Val extends ScheduleInteractionState>
    implements $ScheduleInteractionStateCopyWith<$Res> {
  _$ScheduleInteractionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reactions = null,
    Object? comments = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      reactions: null == reactions
          ? _value.reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as List<ScheduleReaction>,
      comments: null == comments
          ? _value.comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<ScheduleComment>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ScheduleInteractionStateImplCopyWith<$Res>
    implements $ScheduleInteractionStateCopyWith<$Res> {
  factory _$$ScheduleInteractionStateImplCopyWith(
          _$ScheduleInteractionStateImpl value,
          $Res Function(_$ScheduleInteractionStateImpl) then) =
      __$$ScheduleInteractionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ScheduleReaction> reactions,
      List<ScheduleComment> comments,
      bool isLoading,
      String? error});
}

/// @nodoc
class __$$ScheduleInteractionStateImplCopyWithImpl<$Res>
    extends _$ScheduleInteractionStateCopyWithImpl<$Res,
        _$ScheduleInteractionStateImpl>
    implements _$$ScheduleInteractionStateImplCopyWith<$Res> {
  __$$ScheduleInteractionStateImplCopyWithImpl(
      _$ScheduleInteractionStateImpl _value,
      $Res Function(_$ScheduleInteractionStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reactions = null,
    Object? comments = null,
    Object? isLoading = null,
    Object? error = freezed,
  }) {
    return _then(_$ScheduleInteractionStateImpl(
      reactions: null == reactions
          ? _value._reactions
          : reactions // ignore: cast_nullable_to_non_nullable
              as List<ScheduleReaction>,
      comments: null == comments
          ? _value._comments
          : comments // ignore: cast_nullable_to_non_nullable
              as List<ScheduleComment>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ScheduleInteractionStateImpl extends _ScheduleInteractionState {
  const _$ScheduleInteractionStateImpl(
      {final List<ScheduleReaction> reactions = const [],
      final List<ScheduleComment> comments = const [],
      this.isLoading = false,
      this.error})
      : _reactions = reactions,
        _comments = comments,
        super._();

  final List<ScheduleReaction> _reactions;
  @override
  @JsonKey()
  List<ScheduleReaction> get reactions {
    if (_reactions is EqualUnmodifiableListView) return _reactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reactions);
  }

  final List<ScheduleComment> _comments;
  @override
  @JsonKey()
  List<ScheduleComment> get comments {
    if (_comments is EqualUnmodifiableListView) return _comments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_comments);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? error;

  @override
  String toString() {
    return 'ScheduleInteractionState(reactions: $reactions, comments: $comments, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ScheduleInteractionStateImpl &&
            const DeepCollectionEquality()
                .equals(other._reactions, _reactions) &&
            const DeepCollectionEquality().equals(other._comments, _comments) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_reactions),
      const DeepCollectionEquality().hash(_comments),
      isLoading,
      error);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ScheduleInteractionStateImplCopyWith<_$ScheduleInteractionStateImpl>
      get copyWith => __$$ScheduleInteractionStateImplCopyWithImpl<
          _$ScheduleInteractionStateImpl>(this, _$identity);
}

abstract class _ScheduleInteractionState extends ScheduleInteractionState {
  const factory _ScheduleInteractionState(
      {final List<ScheduleReaction> reactions,
      final List<ScheduleComment> comments,
      final bool isLoading,
      final String? error}) = _$ScheduleInteractionStateImpl;
  const _ScheduleInteractionState._() : super._();

  @override
  List<ScheduleReaction> get reactions;
  @override
  List<ScheduleComment> get comments;
  @override
  bool get isLoading;
  @override
  String? get error;
  @override
  @JsonKey(ignore: true)
  _$$ScheduleInteractionStateImplCopyWith<_$ScheduleInteractionStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
