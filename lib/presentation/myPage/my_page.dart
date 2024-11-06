import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation_provider.dart';

class MyPage extends ConsumerWidget {
  const MyPage({Key? key}) : super(key: key);

  // マイページを表示するウィジェット
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // ユーザー検索画面への遷移
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('ユーザー情報が取得できません'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('ユーザーID: ${user.id}'),
                Text('表示名: ${user.profile.name}'),
                // その他ユーザー情報
                ElevatedButton(
                  onPressed: () {
                    // プロフィール編集画面への遷移
                  },
                  child: const Text('プロフィール編集'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref.read(authRepositoryProvider).signOut();
                  },
                  child: const Text('ログアウト'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('エラーが発生しました: $e')),
      ),
    );
  }
}