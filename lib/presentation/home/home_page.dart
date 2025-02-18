import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_state.dart';
import '../list/create_list_page.dart';
import '../list/list_detail_page.dart';
import '../presentation_provider.dart';
import '../friend/friend_search_page.dart';
import '../notification/notification_list_page.dart';
import '../widgets/notification_badge.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return _tabController.index == 0
        ? FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FriendSearchPage(),
                ),
              );
            },
            child: const Icon(Icons.person_add),
          )
        : FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateListPage(),
                ),
              );
            },
            child: const Icon(Icons.add),
          );
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(userFriendsStreamProvider);
    final listsAsync = ref.watch(userListsStreamProvider);

    ref.listen(authNotifierProvider, (previous, next) {
      next.whenData((authState) {
        if (authState.status == AuthStatus.authenticated && authState.user != null) {
          ref.invalidate(userFriendsStreamProvider);
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('ホーム'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: IconButton(
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
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      body: Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              tabBarTheme: TabBarTheme(
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
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
    );
  }
}
