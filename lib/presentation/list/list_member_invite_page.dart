import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_state.dart';
import '../../domain/entity/list.dart';
import '../presentation_provider.dart';

/// リストメンバー追加ページ
class ListMemberInvitePage extends ConsumerStatefulWidget {
  const ListMemberInvitePage({
    super.key,
    required this.list,
  });

  final UserList list;

  @override
  ConsumerState<ListMemberInvitePage> createState() =>
      _ListMemberInvitePageState();
}

class _ListMemberInvitePageState extends ConsumerState<ListMemberInvitePage> {
  Set<String> selectedFriends = {};

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authNotifierProvider);

    return authStateAsync.when(
      data: (state) {
        if (state.status != AuthStatus.authenticated || state.user == null) {
          return const Scaffold(
            body: Center(child: Text('認証が必要です')),
          );
        }

        final friendsAsync = ref.watch(userFriendsStreamProvider);

        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.list.listName}にメンバーを追加'),
          ),
          body: friendsAsync.when(
            data: (friends) {
              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final friendId = friend.id;
                  final isSelected = selectedFriends.contains(friendId);
                  final isInList = widget.list.memberIds.contains(friendId);

                  return ListTile(
                    enabled: !isInList,
                    tileColor: isInList ? Colors.grey.withOpacity(0.1) : null,
                    leading: CircleAvatar(
                      backgroundImage: friend.iconUrl != null
                          ? NetworkImage(friend.iconUrl!)
                          : null,
                      child: friend.iconUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(friend.displayName),
                    subtitle:
                        friend.shortBio != null && friend.shortBio!.isNotEmpty
                            ? Text(
                                friend.shortBio!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : null,
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: isInList
                          ? null
                          : (bool? value) {
                              setState(() {
                                if (value == true) {
                                  selectedFriends.add(friendId);
                                } else {
                                  selectedFriends.remove(friendId);
                                }
                              });
                            },
                    ),
                    onTap: isInList
                        ? null
                        : () {
                            setState(() {
                              if (selectedFriends.contains(friendId)) {
                                selectedFriends.remove(friendId);
                              } else {
                                selectedFriends.add(friendId);
                              }
                            });
                          },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('エラーが発生しました: $error'),
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: selectedFriends.isEmpty
                    ? null
                    : () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        try {
                          // 選択された友達をリストに追加
                          for (final friendId in selectedFriends) {
                            // リストにメンバーを追加
                            await ref
                                .read(listNotifierProvider.notifier)
                                .addMember(
                                  widget.list.id,
                                  friendId,
                                );
                          }
                          if (mounted) {
                            navigator.pop();
                          }
                        } catch (e) {
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('メンバーの追加に失敗しました: $e')),
                            );
                          }
                        }
                      },
                child: Text('選択したメンバー(${selectedFriends.length}名)を追加'),
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }
}
