import 'package:flutter/material.dart';
import '../../../domain/entity/user.dart';
import '../../widgets/expandable_user_avatar.dart';
import 'search_id_display.dart';

/// ユーザープロフィールカードを表示するウィジェット
///
/// [user] 表示するユーザー情報
/// [onEditPressed] プロフィール編集ボタンが押された時のコールバック
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.user,
    required this.onEditPressed,
  });
  final UserModel user;
  final VoidCallback onEditPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserAvatar(context),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName.isNotEmpty ? user.displayName : 'ユーザー',
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

  /// ユーザーアバターを構築
  /// 画像URLがある場合はタップで拡大表示する。
  Widget _buildUserAvatar(BuildContext context) {
    return ExpandableUserAvatar(
      imageUrl: user.iconUrl,
      size: 80,
    );
  }
}
