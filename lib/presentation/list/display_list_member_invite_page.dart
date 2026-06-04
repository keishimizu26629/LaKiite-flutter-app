import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/entity/display_list.dart';
import 'package:lakiite/domain/service/display_list_membership.dart';
import 'package:lakiite/presentation/friend/friend_providers.dart';
import 'package:lakiite/presentation/list/display_list_providers.dart';

class DisplayListMemberInvitePage extends ConsumerStatefulWidget {
  const DisplayListMemberInvitePage({super.key, required this.displayList});

  final DisplayList displayList;

  @override
  ConsumerState<DisplayListMemberInvitePage> createState() =>
      _DisplayListMemberInvitePageState();
}

class _DisplayListMemberInvitePageState
    extends ConsumerState<DisplayListMemberInvitePage> {
  final Set<String> _selectedFriendIds = {};

  @override
  Widget build(BuildContext context) {
    final authStateAsync = ref.watch(authNotifierProvider);

    return authStateAsync.when(
      data: (state) {
        if (state.status != AuthStatus.authenticated || state.user == null) {
          return const Scaffold(body: Center(child: Text('認証が必要です')));
        }

        final friendsAsync = ref.watch(userFriendsStreamProvider);
        final displayLists =
            ref.watch(userDisplayListsStreamProvider).valueOrNull ??
                const <DisplayList>[];
        final matchingDisplayLists = displayLists
            .where((item) => item.id == widget.displayList.id)
            .toList();
        final currentDisplayList = matchingDisplayLists.isEmpty
            ? widget.displayList
            : matchingDisplayLists.first;
        final selectedFriendsToAdd = _selectedFriendIds
            .where((friendId) =>
                !currentDisplayList.memberIds.contains(friendId) &&
                DisplayListMembership.findConflictingList(
                      displayLists: displayLists,
                      targetListId: currentDisplayList.id,
                      userId: friendId,
                    ) ==
                    null)
            .toSet();

        return Scaffold(
          appBar: AppBar(
            title: Text('${currentDisplayList.name}にメンバーを追加'),
          ),
          body: friendsAsync.when(
            data: (friends) {
              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  final friendId = friend.id;
                  final isInCurrentList =
                      currentDisplayList.memberIds.contains(friendId);
                  final conflictingList =
                      DisplayListMembership.findConflictingList(
                    displayLists: displayLists,
                    targetListId: currentDisplayList.id,
                    userId: friendId,
                  );
                  final isUnavailable =
                      isInCurrentList || conflictingList != null;
                  final isSelected =
                      !isUnavailable && selectedFriendsToAdd.contains(friendId);
                  final subtitle = conflictingList != null
                      ? '${conflictingList.name}に追加済み'
                      : isInCurrentList
                          ? 'このリストに追加済み'
                          : friend.shortBio;

                  return ListTile(
                    enabled: !isUnavailable,
                    tileColor: isUnavailable
                        ? Colors.grey.withValues(alpha: 0.1)
                        : null,
                    leading: CircleAvatar(
                      backgroundImage: friend.iconUrl != null
                          ? NetworkImage(friend.iconUrl!)
                          : null,
                      child: friend.iconUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(friend.displayName),
                    subtitle: subtitle != null && subtitle.isNotEmpty
                        ? Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[600]),
                          )
                        : null,
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: isUnavailable
                          ? null
                          : (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedFriendIds.add(friendId);
                                } else {
                                  _selectedFriendIds.remove(friendId);
                                }
                              });
                            },
                    ),
                    onTap: isUnavailable
                        ? null
                        : () {
                            setState(() {
                              if (_selectedFriendIds.contains(friendId)) {
                                _selectedFriendIds.remove(friendId);
                              } else {
                                _selectedFriendIds.add(friendId);
                              }
                            });
                          },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('エラーが発生しました: $error')),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: selectedFriendsToAdd.isEmpty
                    ? null
                    : () async {
                        final navigator = Navigator.of(context);
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        try {
                          for (final friendId in selectedFriendsToAdd) {
                            await ref
                                .read(displayListRepositoryProvider)
                                .addMember(
                                  ownerId: currentDisplayList.ownerId,
                                  displayListId: currentDisplayList.id,
                                  userId: friendId,
                                );
                          }
                          navigator.pop();
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('メンバーの追加に失敗しました: $e')),
                          );
                        }
                      },
                child: Text('選択したメンバー(${selectedFriendsToAdd.length}名)を追加'),
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('エラーが発生しました: $error'))),
    );
  }
}
