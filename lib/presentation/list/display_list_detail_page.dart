import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/domain/entity/display_list.dart';
import 'package:lakiite/presentation/list/display_list_edit_page.dart';
import 'package:lakiite/presentation/list/display_list_member_invite_page.dart';
import 'package:lakiite/presentation/list/display_list_palette.dart';
import 'package:lakiite/presentation/list/display_list_providers.dart';
import 'package:lakiite/presentation/list/list_detail_scaffold.dart';
import 'package:lakiite/presentation/list/list_member_profile_tile.dart';

class DisplayListDetailPage extends ConsumerWidget {
  const DisplayListDetailPage({super.key, required this.displayList});

  final DisplayList displayList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayListsAsync = ref.watch(userDisplayListsStreamProvider);
    final watchedDisplayLists = displayListsAsync.valueOrNull ?? const [];
    final matchingDisplayLists =
        watchedDisplayLists.where((item) => item.id == displayList.id).toList();
    final currentDisplayList =
        matchingDisplayLists.isEmpty ? displayList : matchingDisplayLists.first;
    final listColor =
        DisplayListPalette.colorForKey(currentDisplayList.colorKey);

    return ListDetailScaffold(
      appBarTitle: '表示用リストの詳細',
      title: currentDisplayList.name,
      leading: CircleAvatar(
        radius: 40,
        backgroundColor: listColor.withValues(alpha: 0.18),
        child: Icon(Icons.palette, size: 40, color: listColor),
      ),
      memberCount: currentDisplayList.memberIds.length,
      onEdit: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DisplayListEditPage(
              displayList: currentDisplayList,
            ),
          ),
        );
      },
      onAddMember: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DisplayListMemberInvitePage(
              displayList: currentDisplayList,
            ),
          ),
        );
      },
      onDelete: () {
        return ref.read(displayListRepositoryProvider).deleteDisplayList(
              ownerId: currentDisplayList.ownerId,
              displayListId: currentDisplayList.id,
            );
      },
      deleteDialogTitle: '表示用リストを削除',
      deleteDialogMessage: 'この表示用リストを削除してもよろしいですか？',
      memberIds: currentDisplayList.memberIds,
      memberTileBuilder: (memberId) {
        return ListMemberProfileTile(
          memberId: memberId,
          trailing: IconButton(
            tooltip: 'メンバーから削除',
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () async {
              await ref.read(displayListRepositoryProvider).removeMember(
                    ownerId: currentDisplayList.ownerId,
                    displayListId: currentDisplayList.id,
                    userId: memberId,
                  );
            },
          ),
        );
      },
    );
  }
}
