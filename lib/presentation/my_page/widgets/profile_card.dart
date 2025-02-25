import 'package:flutter/material.dart';
import '../../../domain/entity/user.dart';
import 'search_id_display.dart';

/// ユーザープロフィールカードを表示するウィジェット
///
/// [user] 表示するユーザー情報
/// [onEditPressed] プロフィール編集ボタンが押された時のコールバック
class ProfileCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEditPressed;

  const ProfileCard({
    super.key,
    required this.user,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              backgroundImage:
                  user.iconUrl != null ? NetworkImage(user.iconUrl!) : null,
              child: user.iconUrl == null
                  ? const Icon(Icons.person, size: 40, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SearchIdDisplay(searchId: user.searchId),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onEditPressed,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text('プロフィールを編集'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
