import 'package:flutter/material.dart';

class ListSummaryTile extends StatelessWidget {
  const ListSummaryTile({
    super.key,
    required this.title,
    required this.memberCount,
    required this.leading,
    required this.onTap,
  });

  final String title;
  final int memberCount;
  final Widget leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text('$memberCount人のメンバー'),
      onTap: onTap,
    );
  }
}
