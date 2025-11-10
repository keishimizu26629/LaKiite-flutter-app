import 'package:flutter/material.dart';

/// ユーザーの一言コメントを表示するウィジェット
///
/// [shortBio] 表示する一言コメント
class ShortBioCard extends StatelessWidget {
  const ShortBioCard({
    super.key,
    this.shortBio,
  });

  final String? shortBio;

  @override
  Widget build(BuildContext context) {
    // shortBioがnullまたは空文字の場合の処理
    String displayText;
    TextStyle textStyle;

    if (shortBio == null || shortBio!.trim().isEmpty) {
      displayText = '一言コメントがありません';
      textStyle = TextStyle(
        fontSize: 16,
        color: Colors.grey[500],
        fontStyle: FontStyle.italic,
      );
    } else {
      displayText = shortBio!.trim();
      textStyle = TextStyle(
        fontSize: 16,
        color: Colors.grey[800],
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: Text(
          displayText,
          style: textStyle,
        ),
      ),
    );
  }
}
