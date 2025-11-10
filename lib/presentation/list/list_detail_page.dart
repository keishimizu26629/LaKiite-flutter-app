import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/list.dart';
import '../../domain/entity/user.dart';
import '../presentation_provider.dart';
import 'list_member_invite_page.dart';
import 'list_edit_page.dart';

/// プライベートリストの詳細画面を表示するウィジェット
///
/// 機能:
/// - リストの詳細情報の表示
/// - リストメンバーの表示
/// - リストの編集・削除
class ListDetailPage extends ConsumerStatefulWidget {
  const ListDetailPage({super.key, required this.list});

  final UserList list;

  @override
  ConsumerState<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends ConsumerState<ListDetailPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listAsync = ref.watch(listStreamProvider(widget.list.id));

    return listAsync.when(
      data: (list) {
        if (list == null) {
          return const Scaffold(
            body: Center(child: Text('リストが見つかりません')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('リストの詳細'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('リストを削除'),
                        content: const Text('このリストを削除してもよろしいですか？'),
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

                    if (confirmed == true) {
                      try {
                        await ref
                            .read(listNotifierProvider.notifier)
                            .deleteList(list.id);
                        if (mounted) {
                          navigator.pop();
                        }
                      } catch (e) {
                        if (mounted) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                                content: Text('削除に失敗しました: ${e.toString()}')),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('リストを削除'),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // リスト情報セクション
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // リストアイコン
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: widget.list.iconUrl != null
                            ? NetworkImage(widget.list.iconUrl!)
                            : null,
                        child: widget.list.iconUrl == null
                            ? const Icon(Icons.list, size: 40)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.list.listName,
                              style: theme.textTheme.headlineSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ListEditPage(list: widget.list),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('リストを編集'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // リストの説明
                if (widget.list.description != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      widget.list.description!,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                const SizedBox(height: 16),
                // メンバー数
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Text(
                        'メンバー',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(width: 8),
                      Text('${widget.list.memberIds.length}人'),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ListMemberInvitePage(list: widget.list),
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
                // メンバーリスト
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: widget.list.memberIds.length,
                  itemBuilder: (context, index) {
                    final memberId = widget.list.memberIds[index];
                    return FutureBuilder<PublicUserModel?>(
                      future: ref
                          .read(userRepositoryProvider)
                          .getFriendPublicProfile(memberId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircularProgressIndicator(),
                              title: Text('読み込み中...'),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.error),
                              title: Text('エラーが発生しました: ${snapshot.error}'),
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
                            subtitle: member.shortBio != null &&
                                    member.shortBio!.isNotEmpty
                                ? Text(
                                    member.shortBio!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }
}
