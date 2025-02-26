import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// アプリケーション全体で使用する共通のデフォルトユーザーアイコン
class DefaultUserIcon extends StatelessWidget {
  const DefaultUserIcon({
    super.key,
    this.size = 40,
    this.iconSize,
    this.backgroundColor,
    this.iconColor,
  });

  final double size;
  final double? iconSize;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? AppTheme.userIconBackgroundColor,
      child: Icon(
        Icons.person,
        size: iconSize ?? (size * 0.75),
        color: iconColor ?? AppTheme.userIconColor,
      ),
    );
  }
}
