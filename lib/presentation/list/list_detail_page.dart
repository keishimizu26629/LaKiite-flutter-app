import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/list/list_notifier.dart';
import '../../domain/entity/list.dart';
import 'list_member_invite_page.dart';
import 'list_edit_page.dart';
import 'list_detail_scaffold.dart';
import 'list_member_profile_tile.dart';
import 'list_providers.dart';
import 'user_list_icon.dart';

/// プライベートリストの詳細画面を表示するウィジェット
///
/// 機能:
/// - リストの詳細情報の表示
/// - リストメンバーの表示
/// - リストの編集・削除
class ListDetailPage extends ConsumerStatefulWidget {
  const ListDetailPage({super.key, required this.list});
  final UserList list;

  @override
  ConsumerState<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends ConsumerState<ListDetailPage> {
  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(listStreamProvider(widget.list.id));

    return listAsync.when(
      data: (list) {
        if (list == null) {
          return const Scaffold(body: Center(child: Text('リストが見つかりません')));
        }

        return ListDetailScaffold(
          appBarTitle: 'リストの詳細',
          title: list.listName,
          leading: UserListIcon(iconUrl: list.iconUrl, radius: 40),
          description: list.description,
          memberCount: list.memberIds.length,
          onEdit: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ListEditPage(list: list),
              ),
            );
          },
          onAddMember: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ListMemberInvitePage(list: list),
              ),
            );
          },
          onDelete: () {
            return ref.read(listNotifierProvider.notifier).deleteList(list.id);
          },
          deleteDialogTitle: 'リストを削除',
          deleteDialogMessage: 'このリストを削除してもよろしいですか？',
          memberIds: list.memberIds,
          memberTileBuilder: (memberId) {
            return ListMemberProfileTile(memberId: memberId);
          },
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('エラーが発生しました: $error'))),
    );
  }
}
