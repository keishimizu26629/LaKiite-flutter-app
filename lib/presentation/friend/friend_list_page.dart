import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_state.dart';
import '../list/create_list_page.dart';
import '../list/list_detail_page.dart';
import '../presentation_provider.dart';
import '../friend/friend_search_page.dart';
import '../friend/friend_profile_page.dart';
import '../widgets/notification_button.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/default_user_icon.dart';

/// フレンドリストとユーザーリストを表示するページ。
/// タブで切り替えることができ、それぞれのタブに応じたFloatingActionButtonを表示します。
class FriendListPage extends ConsumerStatefulWidget {
  const FriendListPage({super.key});

  @override
  ConsumerState<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends ConsumerState<FriendListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // フローティングボタンをキャッシュするための変数
  late final Widget _friendTabFAB;
  late final Widget _listTabFAB;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // フローティングボタンを事前に構築
    _friendTabFAB = FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const FriendSearchPage(),
          ),
        );
      },
      child: const Icon(Icons.person_add),
    );

    _listTabFAB = FloatingActionButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CreateListPage(),
          ),
        );
      },
      child: const Icon(Icons.post_add_outlined),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  /// タブの変更を処理するメソッド。
  /// タブの切り替えが完了したときにUIを更新します。
  void _handleTabChange() {
    // タブの切り替えが完了したときのみ、FloatingActionButtonの表示を更新
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  /// 現在のタブに応じたFloatingActionButtonを返します。
  /// 事前に構築されたボタンを返すだけなので、再構築は発生しません。
  Widget _buildFloatingActionButton() {
    return _tabController.index == 0 ? _friendTabFAB : _listTabFAB;
  }

  /// フレンドタブの内容を構築します。
  Widget _buildFriendTabContent() {
    // Futureベースのプロバイダーを使用
    final friendsAsync = ref.watch(userFriendsProvider);

    return friendsAsync.when(
      data: (friends) {
        if (friends.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              // プロバイダーを無効化して再取得を強制
              ref.invalidate(userFriendsProvider);
              await ref.read(userFriendsProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                      SizedBox(height: 120),
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'フレンドがいません',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // プロバイダーを無効化して再取得を強制
            ref.invalidate(userFriendsProvider);
            await ref.read(userFriendsProvider.future);
          },
          child: ListView.builder(
          key: const PageStorageKey('friend_list'), // キーを追加してスクロール位置を保持
            physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 58,
          ),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: friend.iconUrl != null
                    ? CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(friend.iconUrl!),
                      )
                    : const DefaultUserIcon(size: 48),
                title: Text(
                  friend.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  friend.shortBio ?? '',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FriendProfilePage(
                        userId: friend.id,
                      ),
                    ),
                  );
                },
              ),
            );
          },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('エラーが発生しました: $error'),
      ),
    );
  }

  /// リストタブの内容を構築します。
  Widget _buildListTabContent() {
    // キャッシュを使用せず、常に最新のデータを表示
    final listsAsync = ref.watch(userListsStreamProvider);
    return listsAsync.when(
      data: (lists) {
        if (lists.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.list_alt,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'リストがありません',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          key: const PageStorageKey('list_list'), // キーを追加してスクロール位置を保持
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 58,
          ),
          itemCount: lists.length,
          itemBuilder: (context, index) {
            final list = lists[index];
            final currentUser = ref.watch(authNotifierProvider).value?.user;
            final otherMemberCount = currentUser != null
                ? list.memberIds.where((id) => id != currentUser.id).length
                : 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      list.iconUrl != null ? NetworkImage(list.iconUrl!) : null,
                  child: list.iconUrl == null
                      ? const Icon(Icons.list, size: 32)
                      : null,
                ),
                title: Text(
                  list.listName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  '$otherMemberCount人のメンバー',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ListDetailPage(list: list),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('エラーが発生しました: $error'),
      ),
    );
  }

  /// ウィジェットのUIを構築します。
  ///
  /// フレンドリストとユーザーリストを含むタブビューを表示し、
  /// 各タブの状態に応じて適切なコンテンツを表示します。
  /// また、通知バッジ付きのアプリバーと広告バナーも含まれます。
  ///
  /// [context] - ウィジェットのビルドコンテキスト
  /// [return] - 構築されたウィジェット
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (state) {
        if (state.status != AuthStatus.authenticated || state.user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'フレンド',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: const [
              NotificationButton(),
            ],
          ),
          floatingActionButton: Padding(
            key: const ValueKey('friend_list_fab'),
            padding: const EdgeInsets.only(bottom: 58),
            child: _buildFloatingActionButton(),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 16,
                  ),
                  tabs: const [
                    Tab(text: 'フレンド'),
                    Tab(text: 'リスト'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    IndexedStack(
                      index: _tabController.index == 0 ? 0 : 1,
                      children: [
                        _buildFriendTabContent(),
                        Container(),
                      ],
                    ),
                    IndexedStack(
                      index: _tabController.index == 1 ? 0 : 1,
                      children: [
                        _buildListTabContent(),
                        Container(),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 50,
                child: BannerAdWidget(uniqueId: 'friend_list_page_ad'),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }
}
