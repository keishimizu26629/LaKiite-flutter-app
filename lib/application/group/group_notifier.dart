import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lakiite/application/group/group_state.dart';
import 'package:lakiite/domain/entity/group.dart';
import 'package:lakiite/domain/service/service_provider.dart';

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
      final group =
          await ref.read(groupManagerProvider).createGroupWithNotifications(
                groupName: groupName,
                memberIds: memberIds,
                ownerId: ownerId,
              );
      state = AsyncValue.data(GroupState.loaded([group]));
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
      await ref.read(groupManagerProvider).updateGroup(group);
      // 更新後、現在の状態を維持するか、再取得するかは要件次第
      state = AsyncValue.data(GroupState.loaded([group]));
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
      await ref.read(groupManagerProvider).deleteGroup(groupId);
      // 削除後は空の状態にするか、残りのグループを表示するかは要件次第
      state = const AsyncValue.data(GroupState.loaded([]));
    } catch (e) {
      state = AsyncValue.data(GroupState.error(e.toString()));
    }
  }

  /// グループにメンバーを追加する
  ///
  /// [groupId] メンバーを追加するグループのID
  /// [userId] 追加するユーザーのID
  /// [invitedByUserId] 招待者のユーザーID
  ///
  /// エラー発生時は[GroupState.error]を返します。
  Future<void> addMember(
      String groupId, String userId, String invitedByUserId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(groupManagerProvider).addMemberWithNotification(
            groupId: groupId,
            userId: userId,
            invitedByUserId: invitedByUserId,
          );
      // 成功時の状態更新は要件に応じて実装
      state = const AsyncValue.data(GroupState.loaded([]));
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
      await ref.read(groupManagerProvider).removeMember(
            groupId: groupId,
            userId: userId,
          );
      // 成功時の状態更新は要件に応じて実装
      state = const AsyncValue.data(GroupState.loaded([]));
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
    ref.read(groupManagerProvider).watchUserGroups(userId).listen(
      (groups) {
        state = AsyncValue.data(GroupState.loaded(groups));
      },
      onError: (error) {
        state = AsyncValue.data(GroupState.error(error.toString()));
      },
    );
  }
}
