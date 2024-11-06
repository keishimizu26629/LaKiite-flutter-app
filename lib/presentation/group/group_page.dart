import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupPage extends ConsumerWidget {
  const GroupPage({Key? key}) : super(key: key);

  // グループ一覧を表示するウィジェット
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // グループリストの取得は省略

    return Scaffold(
      appBar: AppBar(
        title: const Text('グループ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // グループ作成画面への遷移
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          // グループタイルのリスト
        ],
      ),
    );
  }
}