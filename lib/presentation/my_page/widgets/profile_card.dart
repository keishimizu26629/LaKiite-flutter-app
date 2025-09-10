import 'package:flutter/material.dart';
import '../../../domain/entity/user.dart';
import '../../widgets/default_user_icon.dart';
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
  /// nullチェックを行い、適切なフォールバックを提供
  Widget _buildUserAvatar(BuildContext context) {
    // iconUrlがnullまたは空文字列の場合はデフォルトアイコンを使用
    if (user.iconUrl == null || user.iconUrl!.isEmpty) {
      return const DefaultUserIcon(size: 80);
    }

    // NetworkImageでエラーが発生した場合のフォールバックも含める
    return CircleAvatar(
      radius: 40,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Image.network(
          user.iconUrl!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const DefaultUserIcon(size: 80);
          },
          errorBuilder: (context, error, stackTrace) {
            // ネットワークエラーや画像読み込みエラーの場合
            return const DefaultUserIcon(size: 80);
          },
        ),
      ),
    );
  }
}
