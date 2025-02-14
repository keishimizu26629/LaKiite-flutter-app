import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_state.dart';
import '../list/create_list_page.dart';
import '../list/list_detail_page.dart';
import '../presentation_provider.dart';
import '../friend/friend_search_page.dart';
import '../notification/notification_list_page.dart';
import '../widgets/notification_badge.dart';

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
    // フレンドとリストの状態を監視
    final friendsAsync = ref.watch(userFriendsStreamProvider);
    final listsAsync = ref.watch(userListsStreamProvider);

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
            icon: const NotificationBadge(
              child: Icon(Icons.notifications),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationListPage(),
                ),
              );
            },
          ),
        ],
      ),
      // 新規リスト作成ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // リスト作成画面への遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const CreateListPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'フレンド'),
                Tab(text: 'リスト'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // フレンドタブ
                  friendsAsync.when(
                    data: (friends) {
                      if (friends.isEmpty) {
                        return const Center(
                          child: Text('フレンドはいません'),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
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
                            subtitle: Text(friend.searchId.toString()),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        Center(child: Text('エラー: ${error.toString()}')),
                  ),
                  // リストタブ
                  listsAsync.when(
                    data: (lists) {
                      if (lists.isEmpty) {
                        return const Center(
                          child: Text('作成したリストはありません'),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: lists.length,
                        itemBuilder: (context, index) {
                          final list = lists[index];
                          final currentUser = ref.watch(authNotifierProvider).value?.user;
                          // 自分以外のメンバー数を計算
                          final otherMemberCount = currentUser != null
                              ? list.memberIds.where((id) => id != currentUser.id).length
                              : 0;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: list.iconUrl != null
                                  ? NetworkImage(list.iconUrl!)
                                  : null,
                              child: list.iconUrl == null
                                  ? const Icon(Icons.list)
                                  : null,
                            ),
                            title: Text(list.listName),
                            subtitle: Text('${otherMemberCount}人のメンバー'),
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
                    error: (error, stack) =>
                        Center(child: Text('エラー: ${error.toString()}')),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
