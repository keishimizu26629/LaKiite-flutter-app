import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/domain/entity/display_list.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'create_list_page.dart';
import 'create_display_list_page.dart';
import 'display_list_detail_page.dart';
import 'display_list_palette.dart';
import 'display_list_providers.dart';
import 'list_detail_page.dart';
import 'list_providers.dart';
import 'list_summary_tile.dart';
import 'user_list_icon.dart';
import '../widgets/banner_ad_widget.dart';

/// プライベートリスト一覧を表示するウィジェット
///
/// 機能:
/// - ユーザーのプライベートリスト一覧の表示
/// - リストの作成
/// - リストの詳細表示
class ListPage extends ConsumerStatefulWidget {
  const ListPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<ListPage> createState() => _ListPageState();
}

class _ListPageState extends ConsumerState<ListPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final content = _ListContent(
      selectedTabIndex: _tabIndex,
      onTabChanged: (index) => setState(() => _tabIndex = index),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const SizedBox(
          width: double.infinity,
          child: Text(
            'リスト',
            textAlign: TextAlign.center,
          ),
        ),
        centerTitle: true,
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          Expanded(child: content),
          const SizedBox(
            height: 50,
            child: BannerAdWidget(uniqueId: 'list_page_ad'),
          ),
        ],
      ),
    );
  }
}

class _ListContent extends ConsumerWidget {
  const _ListContent({
    required this.selectedTabIndex,
    required this.onTabChanged,
  });

  final int selectedTabIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(userListsStreamProvider);
    final displayListsAsync = ref.watch(userDisplayListsStreamProvider);

    return DefaultTabController(
      length: 2,
      initialIndex: selectedTabIndex,
      child: Stack(
        children: [
          Column(
            children: [
              Material(
                color: Colors.white,
                elevation: 1,
                child: TabBar(
                  onTap: onTabChanged,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  unselectedLabelStyle: const TextStyle(fontSize: 16),
                  tabs: const [
                    Tab(text: '公開用'),
                    Tab(text: '表示用'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _PublicListsView(listsAsync: listsAsync),
                    _DisplayListsView(displayListsAsync: displayListsAsync),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'list_create_fab',
              onPressed: () {
                if (selectedTabIndex == 0) {
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
        ],
      ),
    );
  }
}

class _PublicListsView extends StatelessWidget {
  const _PublicListsView({required this.listsAsync});

  final AsyncValue<List<UserList>> listsAsync;

  @override
  Widget build(BuildContext context) {
    return listsAsync.when(
      data: (lists) {
        if (lists.isEmpty) {
          return const Center(child: Text('公開用リストがありません'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: lists.length,
          itemBuilder: (context, index) {
            final list = lists[index];
            return ListSummaryTile(
              leading: UserListIcon(iconUrl: list.iconUrl),
              title: list.listName,
              memberCount: list.memberIds.length,
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
    );
  }
}

class _DisplayListsView extends StatelessWidget {
  const _DisplayListsView({required this.displayListsAsync});

  final AsyncValue<List<DisplayList>> displayListsAsync;

  @override
  Widget build(BuildContext context) {
    return displayListsAsync.when(
      data: (displayLists) {
        if (displayLists.isEmpty) {
          return const Center(child: Text('表示用リストがありません'));
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          itemCount: displayLists.length,
          itemBuilder: (context, index) {
            final displayList = displayLists[index];
            final color = DisplayListPalette.colorForKey(displayList.colorKey);
            return ListSummaryTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.18),
                child: Icon(Icons.palette, color: color),
              ),
              title: displayList.name,
              memberCount: displayList.memberIds.length,
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
    );
  }
}
