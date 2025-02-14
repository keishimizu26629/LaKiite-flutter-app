import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/notification/notification_notifier.dart';
import '../../domain/entity/notification.dart';

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
    debugPrint('Building NotificationBadge');

    final unreadCountAsyncValue = type != null
        ? ref.watch(unreadNotificationCountByTypeProvider(type!))
        : ref.watch(unreadNotificationCountProvider);

    debugPrint('NotificationBadge - AsyncValue state: $unreadCountAsyncValue');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        unreadCountAsyncValue.when(
          data: (count) {
            debugPrint('NotificationBadge - Unread count: $count');
            if (count == 0) {
              debugPrint('NotificationBadge - No unread notifications');
              return const SizedBox.shrink();
            }

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
            debugPrint('NotificationBadge - Loading state');
            return const SizedBox.shrink();
          },
          error: (error, stack) {
            debugPrint('NotificationBadge - Error: $error\n$stack');
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

/// フレンド申請専用のバッジウィジェット
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

/// グループ招待専用のバッジウィジェット
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
