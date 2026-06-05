import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/list/list_member_profile_tile.dart';
import 'package:lakiite/presentation/list/list_providers.dart';
import 'package:lakiite/presentation/list/user_list_icon.dart';

class ScheduleSharedListsPage extends ConsumerWidget {
  const ScheduleSharedListsPage({super.key, required this.schedule});

  final Schedule schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(userListsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('公開先リスト')),
      body: listsAsync.when(
        data: (lists) {
          final listById = {for (final list in lists) list.id: list};
          final orderedLists = schedule.sharedLists
              .map((listId) => listById[listId])
              .whereType<UserList>()
              .toList();

          if (orderedLists.isEmpty) {
            return const Center(child: Text('公開先リストがありません'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orderedLists.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final list = orderedLists[index];
              return _SharedListSection(list: list);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }
}

class _SharedListSection extends StatelessWidget {
  const _SharedListSection({required this.list});

  final UserList list;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            UserListIcon(iconUrl: list.iconUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                list.listName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${list.memberIds.length}人',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (list.memberIds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'メンバーがいません',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          )
        else
          ...list.memberIds.map(
            (memberId) => ListMemberProfileTile(memberId: memberId),
          ),
      ],
    );
  }
}
