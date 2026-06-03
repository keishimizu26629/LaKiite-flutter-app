import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/domain/entity/display_list.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/list/display_list_edit_page.dart';
import 'package:lakiite/presentation/list/display_list_member_invite_page.dart';
import 'package:lakiite/presentation/list/display_list_palette.dart';
import 'package:lakiite/presentation/list/display_list_providers.dart';

class DisplayListDetailPage extends ConsumerWidget {
  const DisplayListDetailPage({super.key, required this.displayList});

  final DisplayList displayList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayListsAsync = ref.watch(userDisplayListsStreamProvider);
    final watchedDisplayLists = displayListsAsync.valueOrNull ?? const [];
    final matchingDisplayLists =
        watchedDisplayLists.where((item) => item.id == displayList.id).toList();
    final currentDisplayList =
        matchingDisplayLists.isEmpty ? displayList : matchingDisplayLists.first;
    final theme = Theme.of(context);
    final listColor =
        DisplayListPalette.colorForKey(currentDisplayList.colorKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text('表示用リストの詳細'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value != 'delete') {
                return;
              }
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('表示用リストを削除'),
                  content: const Text('この表示用リストを削除してもよろしいですか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('削除'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) {
                return;
              }
              try {
                await ref.read(displayListRepositoryProvider).deleteDisplayList(
                      ownerId: currentDisplayList.ownerId,
                      displayListId: currentDisplayList.id,
                    );
                navigator.pop();
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('削除に失敗しました: $e')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete', child: Text('削除')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: listColor.withValues(alpha: 0.18),
                    child: Icon(Icons.palette, size: 40, color: listColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentDisplayList.name,
                          style: theme.textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DisplayListEditPage(
                                  displayList: currentDisplayList,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('編集'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('メンバー', style: theme.textTheme.titleLarge),
                  const SizedBox(width: 8),
                  Text('${currentDisplayList.memberIds.length}人'),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DisplayListMemberInvitePage(
                            displayList: currentDisplayList,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('友達を追加'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: currentDisplayList.memberIds.length,
              itemBuilder: (context, index) {
                final memberId = currentDisplayList.memberIds[index];
                return FutureBuilder<PublicUserModel?>(
                  future: ref
                      .read(userRepositoryProvider)
                      .getFriendPublicProfile(memberId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Card(
                        margin: EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircularProgressIndicator(),
                          title: Text('読み込み中...'),
                        ),
                      );
                    }
                    final member = snapshot.data;
                    if (member == null) {
                      return const SizedBox.shrink();
                    }
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: member.iconUrl != null
                              ? NetworkImage(member.iconUrl!)
                              : null,
                          child: member.iconUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(member.displayName),
                        trailing: IconButton(
                          tooltip: 'メンバーから削除',
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () async {
                            await ref
                                .read(displayListRepositoryProvider)
                                .removeMember(
                                  ownerId: currentDisplayList.ownerId,
                                  displayListId: currentDisplayList.id,
                                  userId: memberId,
                                );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
