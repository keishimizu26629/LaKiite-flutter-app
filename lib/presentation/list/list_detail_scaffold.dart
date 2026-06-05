import 'package:flutter/material.dart';

class ListDetailScaffold extends StatelessWidget {
  const ListDetailScaffold({
    super.key,
    required this.appBarTitle,
    required this.title,
    required this.leading,
    required this.memberCount,
    required this.onEdit,
    required this.onAddMember,
    required this.onDelete,
    required this.deleteDialogTitle,
    required this.deleteDialogMessage,
    required this.memberIds,
    required this.memberTileBuilder,
    this.description,
  });

  final String appBarTitle;
  final String title;
  final Widget leading;
  final String? description;
  final int memberCount;
  final VoidCallback onEdit;
  final VoidCallback onAddMember;
  final Future<void> Function() onDelete;
  final String deleteDialogTitle;
  final String deleteDialogMessage;
  final List<String> memberIds;
  final Widget Function(String memberId) memberTileBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value != 'delete') {
                return;
              }

              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(deleteDialogTitle),
                  content: Text(deleteDialogMessage),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('削除'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) {
                return;
              }

              try {
                await onDelete();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('削除に失敗しました: $e')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'delete', child: Text('削除')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.headlineSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit),
                          label: const Text('編集'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (description != null && description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(description!, style: theme.textTheme.bodyLarge),
              ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('メンバー', style: theme.textTheme.titleLarge),
                  const SizedBox(width: 8),
                  Text('$memberCount人'),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: onAddMember,
                    icon: const Icon(Icons.person_add),
                    label: const Text('友達を追加'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: memberIds.length,
              itemBuilder: (context, index) {
                return memberTileBuilder(memberIds[index]);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
