import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/list.dart';
import '../presentation_provider.dart';
import 'list_member_invite_page.dart';

/// プライベートリストの詳細画面を表示するウィジェット
///
/// 機能:
/// - リストの詳細情報の表示
/// - リストメンバーの表示
/// - リストの編集・削除
class ListDetailPage extends ConsumerStatefulWidget {
  final UserList list;

  const ListDetailPage({super.key, required this.list});

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
                            .deleteList(list.id, list.ownerId);
                        if (mounted) {
                          Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('削除に失敗しました: ${e.toString()}')),
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
          body: Column(
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
                      backgroundImage: list.iconUrl != null
                          ? NetworkImage(list.iconUrl!)
                          : null,
                      child: list.iconUrl == null
                          ? const Icon(Icons.list, size: 40)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            list.listName,
                            style: theme.textTheme.headlineSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              // TODO: リスト編集機能の実装
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('編集機能は現在開発中です')),
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
              if (list.description != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    list.description!,
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
                    Text('${list.memberIds.length}人'),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ListMemberInvitePage(list: list),
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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: list.memberIds.length,
                  itemBuilder: (context, index) {
                    final memberId = list.memberIds[index];
                    return ref.watch(publicUserStreamProvider(memberId)).when(
                      data: (member) {
                        if (member == null) {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: member.iconUrl != null
                                ? NetworkImage(member.iconUrl!)
                                : null,
                            child: member.iconUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(member.displayName),
                          subtitle: Text(member.searchId.toString()),
                        );
                      },
                      loading: () => const ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('読み込み中...'),
                      ),
                      error: (error, _) => ListTile(
                        leading: const Icon(Icons.error),
                        title: Text('エラーが発生しました: $error'),
                      ),
                    );
                  },
                ),
              ),
            ],
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
