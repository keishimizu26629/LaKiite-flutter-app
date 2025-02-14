import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_state.dart';
import '../../domain/entity/list.dart';
import '../presentation_provider.dart';

/// リストメンバー追加ページ
class ListMemberInvitePage extends ConsumerStatefulWidget {
  final UserList list;

  const ListMemberInvitePage({
    super.key,
    required this.list,
  });

  @override
  ConsumerState<ListMemberInvitePage> createState() => _ListMemberInvitePageState();
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
        final currentUser = state.user;

        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.list.listName}にメンバーを追加'),
          ),
          body: friendsAsync.when(
            data: (friends) {
              // 現在のユーザーのプライベートプロフィールを取得
              final privateProfileAsync = ref.watch(privateUserStreamProvider(currentUser!.id));

              return privateProfileAsync.when(
                data: (privateProfile) {
                  if (privateProfile == null) {
                    return const Center(child: Text('ユーザー情報の取得に失敗しました'));
                  }

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
                        subtitle: Text(friend.searchId.toString()),
                        trailing: Checkbox(
                          value: isSelected,
                          onChanged: isInList ? null : (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedFriends.add(friendId);
                              } else {
                                selectedFriends.remove(friendId);
                              }
                            });
                          },
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('エラーが発生しました: $error'),
                ),
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
                        try {
                          // 選択された友達をリストに追加
                          for (final friendId in selectedFriends) {
                            // リストにメンバーを追加
                            await ref.read(listNotifierProvider.notifier).addMember(
                              widget.list.id,
                              friendId,
                              widget.list.ownerId,
                            );

                            // ユーザーのプライベートプロフィールのlistsフィールドを更新
                            await ref.read(userRepositoryProvider).addToList(
                              currentUser!.id,
                              friendId,
                            );
                          }
                          if (mounted) {
                            Navigator.of(context).pop();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
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
