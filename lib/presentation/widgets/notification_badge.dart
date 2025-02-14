import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/notification/notification_notifier.dart';
import '../../domain/entity/notification.dart' as domain;

typedef NotificationType = domain.NotificationType;

/// 通知の未読カウントを表示するバッジウィジェット
///
/// [child] バッジを表示する対象のウィジェット
/// [type] 通知タイプ。nullの場合は全ての未読通知をカウント
/// [badgeColor] バッジの背景色
/// [textColor] バッジ内のテキスト色
/// [badgeSize] バッジの最小サイズ
/// [fontSize] バッジ内のテキストサイズ
/// [padding] バッジ内のパディング
class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final NotificationType? type;
  final Color badgeColor;
  final Color textColor;
  final double badgeSize;
  final double fontSize;
  final EdgeInsets padding;

  const NotificationBadge({
    super.key,
    required this.child,
    this.type,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
    this.badgeSize = 18,
    this.fontSize = 10,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ウィジェットのビルド開始をログ
    debugPrint('Building NotificationBadge');

    final unreadCountAsyncValue = type != null
        ? ref.watch(unreadNotificationCountByTypeProvider(type!))
        : ref.watch(unreadNotificationCountProvider);

    // 非同期値の状態をログ
    debugPrint('NotificationBadge - AsyncValue state: $unreadCountAsyncValue');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        unreadCountAsyncValue.when(
          data: (count) {
            // 未読カウントをログ
            debugPrint('NotificationBadge - Unread count: $count');
            if (count == 0) {
              debugPrint('NotificationBadge - No unread notifications');
              return const SizedBox.shrink();
            }

            // バッジを表示するPositionedウィジェットを返す
            return Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(badgeSize / 2),
                ),
                constraints: BoxConstraints(
                  minWidth: badgeSize,
                  minHeight: badgeSize,
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
          loading: () {
            // ローディング状態をログ
            debugPrint('NotificationBadge - Loading state');
            return const SizedBox.shrink();
          },
          error: (error, stack) {
            // エラー状態をログ
            debugPrint('NotificationBadge - Error: $error\n$stack');
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

/// フレンド申請の未読通知を表示するバッジウィジェット
///
/// [child] バッジを表示する対象のウィジェット
class FriendRequestBadge extends ConsumerWidget {
  final Widget child;

  const FriendRequestBadge({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationBadge(
      type: NotificationType.friend,
      child: child,
    );
  }
}

/// グループ招待の未読通知を表示するバッジウィジェット
///
/// [child] バッジを表示する対象のウィジェット
class GroupInvitationBadge extends ConsumerWidget {
  final Widget child;

  const GroupInvitationBadge({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationBadge(
      type: NotificationType.groupInvitation,
      child: child,
    );
  }
}
