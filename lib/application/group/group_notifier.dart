import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tarakite/application/group/group_state.dart';
import 'package:tarakite/domain/entity/group.dart';
import 'package:tarakite/presentation/presentation_provider.dart';

part 'group_notifier.g.dart';

/// グループ状態を管理するNotifierクラス
///
/// アプリケーション内でのグループ操作に関する以下の機能を提供します:
/// - グループの作成・更新・削除
/// - グループメンバーの追加・削除
/// - グループ情報の取得と監視
///
/// Riverpodの状態管理システムと統合され、
/// アプリケーション全体でグループ状態を共有します。
@riverpod
class GroupNotifier extends AutoDisposeAsyncNotifier<GroupState> {
  @override
  Future<GroupState> build() async {
    return const GroupState.initial();
  }

  /// 新しいグループを作成する
  ///
  /// [groupName] グループの名前
  /// [memberIds] 初期メンバーのユーザーIDリスト
  /// [ownerId] グループ作成者のユーザーID
  ///
  /// エラー発生時は[GroupState.error]を返します。
  Future<void> createGroup({
    required String groupName,
    required List<String> memberIds,
    required String ownerId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(groupRepositoryProvider).createGroup(
            groupName: groupName,
            memberIds: memberIds,
            ownerId: ownerId,
          );
      await fetchGroups();
    } catch (e) {
      state = AsyncValue.data(GroupState.error(e.toString()));
    }
  }

  /// 全てのグループ情報を取得する
  ///
  /// 取得成功時は[GroupState.loaded]を、
  /// エラー発生時は[GroupState.error]を返します。
  Future<void> fetchGroups() async {
    state = const AsyncValue.loading();
    try {
      final groups = await ref.read(groupRepositoryProvider).getGroups();
      state = AsyncValue.data(GroupState.loaded(groups));
    } catch (e) {
      state = AsyncValue.data(GroupState.error(e.toString()));
    }
  }

  /// グループ情報を更新する
  ///
  /// [group] 更新するグループ情報
  ///
  /// エラー発生時は[GroupState.error]を返します。
  Future<void> updateGroup(Group group) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(groupRepositoryProvider).updateGroup(group);
      await fetchGroups();
    } catch (e) {
      state = AsyncValue.data(GroupState.error(e.toString()));
    }
  }

  /// グループを削除する
  ///
  /// [groupId] 削除するグループのID
  ///
  /// エラー発生時は[GroupState.error]を返します。
  Future<void> deleteGroup(String groupId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(groupRepositoryProvider).deleteGroup(groupId);
      await fetchGroups();
    } catch (e) {
      state = AsyncValue.data(GroupState.error(e.toString()));
    }
  }

  /// グループにメンバーを追加する
  ///
  /// [groupId] メンバーを追加するグループのID
  /// [userId] 追加するユーザーのID
  ///
  /// エラー発生時は[GroupState.error]を返します。
  Future<void> addMember(String groupId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(groupRepositoryProvider).addMember(groupId, userId);
      await fetchGroups();
    } catch (e) {
      state = AsyncValue.data(GroupState.error(e.toString()));
    }
  }

  /// グループからメンバーを削除する
  ///
  /// [groupId] メンバーを削除するグループのID
  /// [userId] 削除するユーザーのID
  ///
  /// エラー発生時は[GroupState.error]を返します。
  Future<void> removeMember(String groupId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(groupRepositoryProvider).removeMember(groupId, userId);
      await fetchGroups();
    } catch (e) {
      state = AsyncValue.data(GroupState.error(e.toString()));
    }
  }

  /// 特定のユーザーが所属するグループを監視する
  ///
  /// [userId] 監視対象のユーザーID
  ///
  /// グループリストの変更を[GroupState.loaded]として通知し、
  /// エラー発生時は[GroupState.error]を返します。
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
