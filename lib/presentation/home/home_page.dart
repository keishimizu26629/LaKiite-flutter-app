import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_state.dart';
import '../group/create_group_page.dart';
import '../presentation_provider.dart';
import '../friend/friend_search_page.dart';
import '../friend/friend_request_list_page.dart';
import '../widgets/friend_request_badge.dart';

/// アプリケーションのホーム画面を表示するウィジェット
///
/// 機能:
/// - フレンドリストの表示
/// - 所属グループの表示
/// - 新規グループ作成画面への遷移
///
/// 状態管理:
/// - Riverpodを使用
/// - ユーザーの認証状態に応じた表示
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

/// HomePageの状態を管理するStateクラス
///
/// 管理する状態:
/// - フレンドリストの取得状態
/// - グループリストの取得状態
/// - 認証状態の監視
class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    // フレンドとグループの状態を監視
    final friendsAsync = ref.watch(userFriendsStreamProvider);
    final groupsAsync = ref.watch(userGroupsStreamProvider);

    // 認証状態の変更を監視
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenData((authState) {
        // ユーザーが認証済みの場合の処理
        if (authState.status == AuthStatus.authenticated &&
            authState.user != null) {
          // ユーザー認証状態の変更を監視
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FriendSearchPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const FriendRequestBadge(
              child: Icon(Icons.notifications),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FriendRequestListPage(),
                ),
              );
            },
          ),
        ],
      ),
      // 新規グループ作成ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // グループ作成画面への遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateGroupPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'フレンド',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            // フレンドリストの状態に応じた表示を切り替え
            friendsAsync.when(
              data: (friends) {
                // フレンドが存在しない場合のメッセージを表示
                if (friends.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('フレンドはいません'),
                  );
                }
                // フレンドリストを表示
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: friend.iconUrl != null
                            ? NetworkImage(friend.iconUrl!)
                            : null,
                        child: friend.iconUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(friend.displayName),
                      subtitle: Text(friend.name),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('エラー: ${error.toString()}')),
            ),
            const SizedBox(height: 24),
            Text(
              'グループ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            // グループリストの状態に応じた表示を切り替え
            groupsAsync.when(
              data: (groups) {
                // グループが存在しない場合のメッセージを表示
                if (groups.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('所属しているグループはありません'),
                  );
                }
                // グループリストを表示
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.group),
                      ),
                      title: Text(group.groupName),
                      subtitle: Text('${group.memberIds.length}人のメンバー'),
                      onTap: () {
                        // TODO: グループ詳細画面への遷移を実装
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('エラー: ${error.toString()}')),
            ),
          ],
        ),
      ),
    );
  }
}
