import 'package:flutter/material.dart';

/// ユーザーの一言コメントを表示するウィジェット
///
/// [shortBio] 表示する一言コメント
class ShortBioCard extends StatelessWidget {
  final String? shortBio;

  const ShortBioCard({
    super.key,
    this.shortBio,
  });

  @override
  Widget build(BuildContext context) {
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
          shortBio?.trim() ?? '',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
      ),
    );
  }
}
