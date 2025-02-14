import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/group.dart';
import '../presentation_provider.dart';

class GroupDetailPage extends ConsumerStatefulWidget {
  final Group group;

  const GroupDetailPage({
    Key? key,
    required this.group,
  }) : super(key: key);

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 管理者のユーザー情報を取得
    final ownerUserAsync = ref.watch(userStreamProvider(widget.group.ownerId));

    // タブの定義
    final _tabs = [
      const Tab(text: 'メンバー'),
      const Tab(text: '予定'),
    ];

    // タブの内容
    final _tabViews = [
      // メンバータブ
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: ownerUserAsync.when(
          data: (owner) => owner != null
              ? Card(
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: owner.iconUrl != null
                          ? NetworkImage(owner.iconUrl!)
                          : null,
                      child: owner.iconUrl == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(owner.displayName),
                    subtitle: const Text('管理者'),
                  ),
                )
              : const Card(
                  elevation: 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text('不明なユーザー'),
                    subtitle: Text('管理者'),
                  ),
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('エラー: ${error.toString()}')),
        ),
      ),
      // 予定タブ
      const Center(
        child: Text('予定はありません'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('グループの詳細'),
      ),
      body: Column(
        children: [
          // グループ情報セクション
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // グループアイコン
                CircleAvatar(
                  radius: 40,
                  backgroundImage: widget.group.iconUrl != null
                      ? NetworkImage(widget.group.iconUrl!)
                      : null,
                  child: widget.group.iconUrl == null
                      ? const Icon(Icons.group, size: 40)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.group.groupName,
                        style: Theme.of(context).textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: グループ編集機能の実装
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('編集機能は現在開発中です')),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('グループを編集'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // タブバー
          TabBar(
            controller: _tabController,
            tabs: _tabs,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
          ),
          // タブの内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabViews,
            ),
          ),
        ],
      ),
      // メンバー追加ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: メンバー追加機能の実装
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('メンバー追加機能は現在開発中です')),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
