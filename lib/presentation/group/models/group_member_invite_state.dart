import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entity/user.dart';
import 'search_user_model.dart' as search;

/// グループメンバー招待画面の状態を管理するクラス
class GroupMemberInviteState {
  final AsyncValue<search.SearchUserModel?> searchResult;
  final List<UserModel> friends;
  final Set<String> selectedFriends;
  final Set<String> groupMembers;
  final Set<String> pendingInvitations;
  final String? message;

  const GroupMemberInviteState({
    this.searchResult = const AsyncValue.data(null),
    this.friends = const [],
    this.selectedFriends = const {},
    this.groupMembers = const {},
    this.pendingInvitations = const {},
    this.message,
  });

  /// 状態を更新するためのコピーメソッド
  GroupMemberInviteState copyWith({
    AsyncValue<search.SearchUserModel?>? searchResult,
    List<UserModel>? friends,
    Set<String>? selectedFriends,
    Set<String>? groupMembers,
    Set<String>? pendingInvitations,
    String? message,
  }) {
    return GroupMemberInviteState(
      searchResult: searchResult ?? this.searchResult,
      friends: friends ?? this.friends,
      selectedFriends: selectedFriends ?? this.selectedFriends,
      groupMembers: groupMembers ?? this.groupMembers,
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
      message: message,
    );
  }

  /// ユーザーが招待可能かどうかを判定
  bool isInvitable(String userId) {
    return !groupMembers.contains(userId) && !pendingInvitations.contains(userId);
  }
}
