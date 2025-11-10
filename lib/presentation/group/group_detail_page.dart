import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/group.dart';
import '../presentation_provider.dart';
import 'group_member_invite_page.dart';

/// グループの詳細情報を表示するページ
///
/// グループのメンバー一覧や予定を表示し、メンバーの招待や
/// グループ情報の編集機能を提供する
class GroupDetailPage extends ConsumerStatefulWidget {
  const GroupDetailPage({
    super.key,
    required this.group,
  });

  final Group group;

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // タブの定義を定数として切り出し
  static const _tabs = [
    Tab(text: 'メンバー'),
    Tab(text: '予定'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
    final theme = Theme.of(context);

    /// メンバータブの内容を構築
    Widget buildMemberTab() {
      return Padding(
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
      );
    }

    /// 予定タブの内容を構築
    Widget buildScheduleTab() {
      return const Center(
        child: Text('予定はありません'),
      );
    }

    // タブの内容を定義
    final tabViews = [
      buildMemberTab(),
      buildScheduleTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('グループの詳細'),
      ),
      body: Column(
        children: [
          // グループ情報セクション
          Padding(
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
                        style: theme.textTheme.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
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
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.primaryColor,
          ),
          // タブの内容
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabViews,
            ),
          ),
        ],
      ),
      // メンバー追加ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => GroupMemberInvitePage(group: widget.group),
            ),
          );
        },
        tooltip: 'メンバーを招待', // ツールチップを追加
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
