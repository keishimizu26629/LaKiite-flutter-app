import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// アプリケーション全体で使用する共通のデフォルトユーザーアイコン
/// プロフィール画面でのクラッシュを防ぐため、null安全性を強化
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
    // サイズの妥当性チェック
    final validSize = size > 0 ? size : 40.0;
    final validIconSize = iconSize ?? (validSize * 0.75);

    try {
      return CircleAvatar(
        radius: validSize / 2,
        backgroundColor: backgroundColor ??
            (Theme.of(context).brightness == Brightness.light
                ? AppTheme.userIconBackgroundColor
                : Colors.grey[600]),
        child: Icon(
          Icons.person,
          size: validIconSize > 0 ? validIconSize : validSize * 0.75,
          color: iconColor ??
              (Theme.of(context).brightness == Brightness.light
                  ? AppTheme.userIconColor
                  : Colors.white),
        ),
      );
    } catch (e) {
      // エラーが発生した場合のフォールバック
      return Container(
        width: validSize,
        height: validSize,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey,
        ),
        child: Icon(
          Icons.person,
          size: validSize * 0.75,
          color: Colors.white,
        ),
      );
    }
  }
}
