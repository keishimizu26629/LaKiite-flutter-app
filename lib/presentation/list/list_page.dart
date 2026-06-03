import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'create_list_page.dart';
import 'create_display_list_page.dart';
import 'display_list_detail_page.dart';
import 'display_list_palette.dart';
import 'display_list_providers.dart';
import 'list_detail_page.dart';
import 'list_providers.dart';

/// プライベートリスト一覧を表示するウィジェット
///
/// 機能:
/// - ユーザーのプライベートリスト一覧の表示
/// - リストの作成
/// - リストの詳細表示
class ListPage extends ConsumerStatefulWidget {
  const ListPage({super.key});

  @override
  ConsumerState<ListPage> createState() => _ListPageState();
}

class _ListPageState extends ConsumerState<ListPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final listsAsync = ref.watch(userListsStreamProvider);
    final displayListsAsync = ref.watch(userDisplayListsStreamProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('リスト'),
          bottom: TabBar(
            onTap: (index) => setState(() => _tabIndex = index),
            tabs: const [
              Tab(text: '公開用'),
              Tab(text: '表示用'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            listsAsync.when(
              data: (lists) {
                if (lists.isEmpty) {
                  return const Center(child: Text('公開用リストがありません'));
                }

                return ListView.builder(
                  itemCount: lists.length,
                  itemBuilder: (context, index) {
                    final list = lists[index];
                    return ListTile(
                      leading: const Icon(Icons.list),
                      title: Text(list.listName),
                      subtitle: Text('${list.memberIds.length}人のメンバー'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ListDetailPage(list: list),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('エラーが発生しました: $error')),
            ),
            displayListsAsync.when(
              data: (displayLists) {
                if (displayLists.isEmpty) {
                  return const Center(child: Text('表示用リストがありません'));
                }

                return ListView.builder(
                  itemCount: displayLists.length,
                  itemBuilder: (context, index) {
                    final displayList = displayLists[index];
                    final color =
                        DisplayListPalette.colorForKey(displayList.colorKey);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.18),
                        child: Icon(Icons.palette, color: color),
                      ),
                      title: Text(displayList.name),
                      subtitle: Text('${displayList.memberIds.length}人のメンバー'),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DisplayListDetailPage(
                              displayList: displayList,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('エラーが発生しました: $error')),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (_tabIndex == 0) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateListPage(),
                ),
              );
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateDisplayListPage(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
