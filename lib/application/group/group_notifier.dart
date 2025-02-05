import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tarakite/application/group/group_state.dart';
import 'package:tarakite/domain/entity/group.dart';
import 'package:tarakite/presentation/presentation_provider.dart';

part 'group_notifier.g.dart';

@riverpod
class GroupNotifier extends AutoDisposeAsyncNotifier<GroupState> {
  @override
  Future<GroupState> build() async {
    return const GroupState.initial();
  }

  Future<void> createGroup({
    required String groupName,
    required List<String> memberIds,
    required String createdBy,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(groupRepositoryProvider).createGroup(
            groupName: groupName,
            memberIds: memberIds,
            createdBy: createdBy,
          );
      await fetchGroups();
    } catch (e) {
      state = AsyncValue.data(GroupState.error(e.toString()));
    }
  }

  Future<void> fetchGroups() async {
    state = const AsyncValue.loading();
    try {
      final groups = await ref.read(groupRepositoryProvider).getGroups();
      state = AsyncValue.data(GroupState.loaded(groups));
    } catch (e) {
      state = AsyncValue.data(GroupState.error(e.toString()));
    }
  }

  Future<void> updateGroup(Group group) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(groupRepositoryProvider).updateGroup(group);
      await fetchGroups();
    } catch (e) {
      state = AsyncValue.data(GroupState.error(e.toString()));
    }
  }

  Future<void> deleteGroup(String groupId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(groupRepositoryProvider).deleteGroup(groupId);
      await fetchGroups();
    } catch (e) {
      state = AsyncValue.data(GroupState.error(e.toString()));
    }
  }

  Future<void> addMember(String groupId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(groupRepositoryProvider).addMember(groupId, userId);
      await fetchGroups();
    } catch (e) {
      state = AsyncValue.data(GroupState.error(e.toString()));
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(groupRepositoryProvider).removeMember(groupId, userId);
      await fetchGroups();
    } catch (e) {
      state = AsyncValue.data(GroupState.error(e.toString()));
    }
  }

  void watchUserGroups(String userId) {
    ref.read(groupRepositoryProvider).watchUserGroups(userId).listen(
      (groups) {
        state = AsyncValue.data(GroupState.loaded(groups));
      },
      onError: (error) {
        state = AsyncValue.data(GroupState.error(error.toString()));
      },
    );
  }
}
