import 'package:flutter/material.dart';
import '../models/search_user_model.dart';

/// ユーザー検索結果を表示するダイアログ
class UserSearchDialog extends StatelessWidget {
  const UserSearchDialog({
    super.key,
    required this.user,
    required this.onCancel,
    required this.onSelect,
  });

  final SearchUserModel user;
  final VoidCallback onCancel;
  final Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: 250,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage:
                  user.iconUrl.isNotEmpty ? NetworkImage(user.iconUrl) : null,
              child: user.iconUrl.isEmpty
                  ? const Icon(Icons.person, size: 40)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              user.displayName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${user.searchId}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            if (user.hasPendingRequest)
              ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: const Text('招待済み'),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('キャンセル'),
                  ),
                  ElevatedButton(
                    onPressed: () => onSelect(user.id),
                    child: const Text('選択'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
