import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/value/user_id.dart';
import '../../theme/app_theme.dart';

/// ユーザーの検索ID表示ウィジェット
///
/// [searchId] 表示する検索ID
class SearchIdDisplay extends StatelessWidget {
  final UserId searchId;

  const SearchIdDisplay({
    super.key,
    required this.searchId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Clipboard.setData(
          ClipboardData(text: searchId.toString()),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('検索IDをコピーしました')),
          );
        }
      },
      child: Row(
        children: [
          Text(
            '@$searchId',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).primaryColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.copy,
            size: 14,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}
