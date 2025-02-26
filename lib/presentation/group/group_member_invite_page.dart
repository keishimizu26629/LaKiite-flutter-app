import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/group.dart';
import '../../application/group/group_member_invite_notifier.dart';
import 'widgets/user_search_dialog.dart';
import 'widgets/friend_list_tile.dart';

/// グループメンバー招待ページ
class GroupMemberInvitePage extends ConsumerStatefulWidget {
  final Group group;

  const GroupMemberInvitePage({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<GroupMemberInvitePage> createState() =>
      _GroupMemberInvitePageState();
}

class _GroupMemberInvitePageState extends ConsumerState<GroupMemberInvitePage> {
  final TextEditingController searchController = TextEditingController();
  bool isDialogShowing = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel =
        ref.watch(groupMemberInviteViewModelProvider(widget.group).notifier);
    final state = ref.watch(groupMemberInviteViewModelProvider(widget.group));

    // ローディング状態の表示
    if (state.friends.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.group.groupName}にメンバーを招待'),
      ),
      body: Column(
        children: [
          // 検索フィールド
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'ユーザーIDを入力',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    viewModel.searchUser(searchController.text);
                  },
                ),
              ),
            ),
          ),

          // 検索結果のローディング表示
          if (state.searchResult.isLoading)
            const Center(child: CircularProgressIndicator()),

          // 検索エラーの表示
          if (state.searchResult.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'エラー: ${state.searchResult.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // 検索結果ダイアログの表示
          if (state.searchResult.hasValue &&
              state.searchResult.value != null &&
              !isDialogShowing)
            Builder(
              builder: (context) {
                isDialogShowing = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (context) => UserSearchDialog(
                      user: state.searchResult.value!,
                      onCancel: () {
                        setState(() {
                          isDialogShowing = false;
                        });
                        viewModel.resetState();
                        Navigator.of(context).pop();
                      },
                      onSelect: (userId) {
                        viewModel.toggleFriendSelection(userId);
                        setState(() {
                          isDialogShowing = false;
                        });
                        Navigator.of(context).pop();
                        searchController.clear();
                      },
                    ),
                  );
                });
                return const SizedBox();
              },
            ),

          // フレンドリスト
          Expanded(
            child: ListView.builder(
              itemCount: state.friends.length,
              itemBuilder: (context, index) {
                final friend = state.friends[index];
                final isSelected = state.selectedFriends.contains(friend.id);
                final isInvitable = state.isInvitable(friend.id);
                return FriendListTile(
                  friend: friend,
                  isSelected: isSelected,
                  isInvitable: isInvitable,
                  isGroupMember: state.groupMembers.contains(friend.id),
                  hasPendingInvitation:
                      state.pendingInvitations.contains(friend.id),
                  onChanged: (bool? value) {
                    viewModel.toggleFriendSelection(friend.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
      // 招待ボタン
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: state.selectedFriends.isEmpty
                ? null
                : () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    await viewModel.sendGroupInvitations(widget.group);
                    if (state.message != null && mounted) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text(state.message!),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
            child: Text('選択したメンバー(${state.selectedFriends.length}名)を招待'),
          ),
        ),
      ),
    );
  }
}
