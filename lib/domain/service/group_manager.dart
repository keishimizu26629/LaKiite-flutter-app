import 'package:lakiite/domain/entity/group.dart';
import 'package:lakiite/domain/entity/notification.dart';
import 'package:lakiite/domain/interfaces/i_group_repository.dart';
import 'package:lakiite/domain/interfaces/i_notification_repository.dart';

/// グループ関連のビジネスロジックを集約するManager
///
/// 機能:
/// - グループ作成時の通知送信
/// - グループメンバー管理
/// - グループ削除時の関連データ清理
abstract class IGroupManager {
  /// 通知付きでグループを作成する
  Future<Group> createGroupWithNotifications({
    required String groupName,
    required List<String> memberIds,
    required String ownerId,
  });

  /// グループメンバーの追加と通知送信
  Future<void> addMemberWithNotification({
    required String groupId,
    required String userId,
    required String invitedByUserId,
  });

  /// グループメンバーの削除
  Future<void> removeMember({
    required String groupId,
    required String userId,
  });

  /// グループ情報の更新
  Future<void> updateGroup(Group group);

  /// グループの削除
  Future<void> deleteGroup(String groupId);

  /// 特定ユーザーのグループ監視
  Stream<List<Group>> watchUserGroups(String userId);
}

class GroupManager implements IGroupManager {
  final IGroupRepository _groupRepository;
  final INotificationRepository _notificationRepository;

  GroupManager(
    this._groupRepository,
    this._notificationRepository,
  );

  @override
  Future<Group> createGroupWithNotifications({
    required String groupName,
    required List<String> memberIds,
    required String ownerId,
  }) async {
    // 1. グループ作成
    final group = await _groupRepository.createGroup(
      groupName: groupName,
      memberIds: memberIds,
      ownerId: ownerId,
    );

    // 2. メンバーに招待通知を送信
    for (final memberId in memberIds) {
      if (memberId != ownerId) {
        final notification = Notification.createGroupInvitation(
          fromUserId: ownerId,
          toUserId: memberId,
          groupId: group.id,
        );
        await _notificationRepository.createNotification(notification);
      }
    }

    return group;
  }

  @override
  Future<void> addMemberWithNotification({
    required String groupId,
    required String userId,
    required String invitedByUserId,
  }) async {
    // 1. グループにメンバー追加
    await _groupRepository.addMember(groupId, userId);

    // 2. 招待通知を送信
    final notification = Notification.createGroupInvitation(
      fromUserId: invitedByUserId,
      toUserId: userId,
      groupId: groupId,
    );
    await _notificationRepository.createNotification(notification);
  }

  @override
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    await _groupRepository.removeMember(groupId, userId);
  }

  @override
  Future<void> updateGroup(Group group) async {
    await _groupRepository.updateGroup(group);
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _groupRepository.deleteGroup(groupId);
  }

  @override
  Stream<List<Group>> watchUserGroups(String userId) {
    return _groupRepository.watchUserGroups(userId);
  }
}
