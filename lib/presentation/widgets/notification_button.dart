import 'package:flutter/material.dart';
import '../notification/notification_list_page.dart';
import './notification_badge.dart';

/// アプリバーに表示する通知ボタン
///
/// 未読通知がある場合は赤いバッジを表示します。
/// タップすると通知一覧画面に遷移します。
class NotificationButton extends StatelessWidget {
  /// 右側のパディング
  final double rightPadding;

  /// アイコンの色
  final Color? iconColor;

  /// アイコンのサイズ
  final double iconSize;

  const NotificationButton({
    super.key,
    this.rightPadding = 24.0,
    this.iconColor,
    this.iconSize = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: rightPadding),
      child: IconButton(
        icon: const NotificationBadge(
          child: Icon(Icons.notifications_outlined),
        ),
        iconSize: iconSize,
        color: iconColor,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const NotificationListPage(),
            ),
          );
        },
      ),
    );
  }
}
