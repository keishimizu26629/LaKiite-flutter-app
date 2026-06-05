import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/presentation/user/user_providers.dart';

class ListMemberProfileTile extends ConsumerWidget {
  const ListMemberProfileTile({
    super.key,
    required this.memberId,
    this.trailing,
  });

  final String memberId;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(publicUserProvider(memberId));

    return memberAsync.when(
      data: (member) {
        if (member == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  member.iconUrl != null ? NetworkImage(member.iconUrl!) : null,
              child: member.iconUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(member.displayName),
            subtitle: member.shortBio != null && member.shortBio!.isNotEmpty
                ? Text(
                    member.shortBio!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: trailing,
          ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircularProgressIndicator(),
          title: Text('読み込み中...'),
        ),
      ),
      error: (error, _) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.error),
          title: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }
}

class EditableListMemberProfileTile extends ConsumerWidget {
  const EditableListMemberProfileTile({
    super.key,
    required this.memberId,
    required this.isExcluded,
    required this.onChanged,
  });

  final String memberId;
  final bool isExcluded;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(publicUserProvider(memberId));

    return memberAsync.when(
      data: (member) {
        if (member == null) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isExcluded ? Colors.grey.shade200 : null,
          child: InkWell(
            onTap: () => onChanged(!isExcluded),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: member.iconUrl != null
                    ? NetworkImage(member.iconUrl!)
                    : null,
                child: member.iconUrl == null ? const Icon(Icons.person) : null,
              ),
              title: Text(
                member.displayName,
                style: isExcluded ? const TextStyle(color: Colors.grey) : null,
              ),
              subtitle: member.shortBio != null && member.shortBio!.isNotEmpty
                  ? Text(
                      member.shortBio!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: Checkbox(
                value: isExcluded,
                onChanged: (value) => onChanged(value ?? false),
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: ListTile(
          leading: CircularProgressIndicator(),
          title: Text('読み込み中...'),
        ),
      ),
      error: (error, _) => Card(
        child: ListTile(
          leading: const Icon(Icons.error),
          title: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }
}
