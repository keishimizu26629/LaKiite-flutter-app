import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation_provider.dart';
import 'create_list_page.dart';
import 'list_detail_page.dart';

/// プライベートリスト一覧を表示するウィジェット
///
/// 機能:
/// - ユーザーのプライベートリスト一覧の表示
/// - リストの作成
/// - リストの詳細表示
class ListPage extends ConsumerWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(userListsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('リスト'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateListPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: listsAsync.when(
        data: (lists) {
          if (lists.isEmpty) {
            return const Center(
              child: Text('リストがありません'),
            );
          }

          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return ListTile(
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
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }
}
