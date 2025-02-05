import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tarakite/domain/entity/group.dart';

part 'group_state.freezed.dart';

@freezed
class GroupState with _$GroupState {
  const factory GroupState.initial() = _Initial;
  const factory GroupState.loading() = _Loading;
  const factory GroupState.loaded(List<Group> groups) = _Loaded;
  const factory GroupState.error(String message) = _Error;
}
