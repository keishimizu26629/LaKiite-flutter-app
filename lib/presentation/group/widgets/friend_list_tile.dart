import 'package:flutter/material.dart';
import '../../../domain/entity/user.dart';

/// フレンドリストの各アイテムを表示するウィジェット
class FriendListTile extends StatelessWidget {
  final UserModel friend;
  final bool isSelected;
  final bool isInvitable;
  final bool isGroupMember;
  final bool hasPendingInvitation;
  final Function(bool?)? onChanged;

  const FriendListTile({
    super.key,
    required this.friend,
    required this.isSelected,
    required this.isInvitable,
    required this.isGroupMember,
    required this.hasPendingInvitation,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isSelected,
      onChanged: isInvitable ? onChanged : null,
      title: Text(
        friend.displayName,
        style: TextStyle(
          color: isInvitable ? null : Colors.grey,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${friend.searchId}'),
          if (isGroupMember)
            const Text(
              'すでにメンバーです',
              style: TextStyle(color: Colors.grey),
            )
          else if (hasPendingInvitation)
            const Text(
              '招待済み',
              style: TextStyle(color: Colors.grey),
            ),
        ],
      ),
      secondary: CircleAvatar(
        backgroundImage:
            friend.iconUrl != null ? NetworkImage(friend.iconUrl!) : null,
        child: friend.iconUrl == null ? const Icon(Icons.person) : null,
      ),
    );
  }
}
