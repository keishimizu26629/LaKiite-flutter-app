import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/group.dart';
import '../../domain/entity/notification.dart' as domain;
import '../../domain/entity/user.dart';
import '../../domain/interfaces/i_user_repository.dart';
import '../../infrastructure/notification_repository.dart';
import '../../application/auth/auth_notifier.dart' as auth;
import '../../presentation/group/models/group_member_invite_state.dart';
import '../../presentation/group/models/search_user_model.dart' as search;

/// グループメンバー招待画面のViewModel Provider
final groupMemberInviteViewModelProvider = StateNotifierProvider.family<
    GroupMemberInviteNotifier, GroupMemberInviteState, Group>((ref, group) {
  final userRepository = ref.watch(auth.userRepositoryProvider);
  final notificationRepository = NotificationRepository();
  final currentUser = ref.watch(auth.authNotifierProvider).value?.user;
  return GroupMemberInviteNotifier(
    userRepository,
    notificationRepository,
    currentUser?.id ?? '',
    currentUser?.publicProfile.displayName ?? '',
    group,
  );
});

/// グループメンバー招待画面のViewModel
class GroupMemberInviteNotifier extends StateNotifier<GroupMemberInviteState> {
  final IUserRepository _userRepository;
  final NotificationRepository _notificationRepository;
  final String _currentUserId;
  final String _currentUserDisplayName;
  final Group _group;

  GroupMemberInviteNotifier(
    this._userRepository,
    this._notificationRepository,
    this._currentUserId,
    this._currentUserDisplayName,
    this._group,
  ) : super(const GroupMemberInviteState()) {
    _initialize();
  }

  /// 初期化処理
  Future<void> _initialize() async {
    try {
      // グループメンバーを設定
      state = state.copyWith(
        groupMembers: Set<String>.from(_group.memberIds),
      );

      // フレンドリストを取得
      await _loadFriends();

      // 招待状態を監視開始
      if (state.friends.isNotEmpty) {
        final friendIds = state.friends.map((f) => f.id).toList();
        await _loadPendingInvitations(friendIds);
      }
    } catch (e) {
      print('Error initializing view model: $e');
    }
  }

  /// 招待状態の読み込み
  Future<void> _loadPendingInvitations(List<String> friendIds) async {
    try {
      final snapshot = await _notificationRepository
          .getPendingGroupInvitations(_group.id, friendIds);
      state = state.copyWith(
        pendingInvitations: Set<String>.from(snapshot),
      );
    } catch (e) {
      print('Error loading pending invitations: $e');
    }
  }

  /// フレンドリストの読み込み
  Future<void> _loadFriends() async {
    try {
      final currentUser = await _userRepository.getUser(_currentUserId);
      if (currentUser == null) return;

      final friendProfiles = await Future.wait(
        currentUser.friends.map((friendId) => _userRepository.getUser(friendId)),
      );

      state = state.copyWith(
        friends: friendProfiles.whereType<UserModel>().toList(),
      );
    } catch (e) {
      print('Error loading friends: $e');
    }
  }

  /// フレンド選択の切り替え
  void toggleFriendSelection(String friendId) {
    final selectedFriends = Set<String>.from(state.selectedFriends);
    if (selectedFriends.contains(friendId)) {
      selectedFriends.remove(friendId);
    } else {
      selectedFriends.add(friendId);
    }
    state = state.copyWith(selectedFriends: selectedFriends);
  }

  /// ユーザー検索
  Future<void> searchUser(String searchId) async {
    try {
      state = state.copyWith(
        searchResult: const AsyncValue.loading(),
        message: null,
      );

      if (_currentUserId.isEmpty) {
        throw Exception('ログインが必要です');
      }

      final user = await _userRepository.findBySearchId(searchId);
      if (user == null) {
        throw Exception('ユーザーが見つかりません');
      }

      if (user.id == _currentUserId) {
        throw Exception('自分自身は招待できません');
      }

      // グループ招待の状態を確認
      bool hasPending = false;
      try {
        // 送信済みの招待を確認
        final hasSentPending = await _notificationRepository.hasPendingGroupInvitation(
          _currentUserId,
          user.id,
          _group.id,
        );

        hasPending = hasSentPending;
      } catch (e) {
        print('Group invitation check error: $e');
      }

      final searchUser = search.SearchUserModel(
        id: user.id,
        displayName: user.displayName,
        searchId: user.searchId,
        iconUrl: user.iconUrl ?? '',
        hasPendingRequest: hasPending,
      );

      state = state.copyWith(
        searchResult: AsyncValue.data(searchUser),
      );
    } catch (e) {
      state = state.copyWith(
        searchResult: AsyncValue.error(e, StackTrace.current),
      );
    }
  }

  /// グループ招待の送信
  Future<void> sendGroupInvitations(Group group) async {
    try {
      if (_currentUserId.isEmpty) {
        throw Exception('ログインが必要です');
      }

      if (state.selectedFriends.isEmpty) {
        throw Exception('招待するメンバーを選択してください');
      }

      // 選択されたすべての友達に招待を送信
      await Future.wait(
        state.selectedFriends.map((friendId) async {
          final friend = state.friends.firstWhere((f) => f.id == friendId);
          final notification = domain.Notification.createGroupInvitation(
            fromUserId: _currentUserId,
            toUserId: friendId,
            groupId: group.id,
            fromUserDisplayName: _currentUserDisplayName,
            toUserDisplayName: friend.displayName,
          );
          await _notificationRepository.createNotification(notification);
        }),
      );

      state = state.copyWith(
        message: '選択したメンバーにグループ招待を送信しました',
        selectedFriends: {},
      );
    } catch (e) {
      state = state.copyWith(
        message: 'エラー: ${e.toString()}',
      );
    }
  }

  /// 状態のリセット
  void resetState() {
    state = state.copyWith(
      searchResult: const AsyncValue.data(null),
      message: null,
    );
  }
}
