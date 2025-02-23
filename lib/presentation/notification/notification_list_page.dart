import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/notification/notification_notifier.dart';
import '../../domain/entity/notification.dart' as domain;

enum NotificationFilter {
  all('すべて'),
  unread('未読'),
  pending('未処理');

  final String label;
  const NotificationFilter(this.label);
}

final notificationFilterProvider =
    StateProvider<NotificationFilter>((ref) => NotificationFilter.all);

class NotificationListPage extends ConsumerWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsyncValue = ref.watch(receivedNotificationsProvider);

    final selectedFilter = ref.watch(notificationFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '通知',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: NotificationFilter.values.map((filter) {
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        filter.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[800],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          ref.read(notificationFilterProvider.notifier).state =
                              filter;
                        }
                      },
                      backgroundColor: Colors.grey[100],
                      selectedColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _NotificationList(
              asyncValue: notificationsAsyncValue,
              filter: selectedFilter,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationList extends ConsumerWidget {
  final AsyncValue<List<domain.Notification>> asyncValue;
  final NotificationFilter filter;

  const _NotificationList({
    required this.asyncValue,
    required this.filter,
  });

  List<domain.Notification> _filterNotifications(
      List<domain.Notification> notifications) {
    switch (filter) {
      case NotificationFilter.all:
        return notifications;
      case NotificationFilter.unread:
        return notifications
            .where((notification) => !notification.isRead)
            .toList();
      case NotificationFilter.pending:
        return notifications
            .where((notification) =>
                notification.status == domain.NotificationStatus.pending)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      data: (notifications) {
        final filteredNotifications = _filterNotifications(notifications);
        if (filteredNotifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  filter == NotificationFilter.all
                      ? '通知はありません'
                      : '${filter.label}の通知はありません',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredNotifications.length,
          itemBuilder: (context, index) {
            final notification = filteredNotifications[index];
            return _NotificationItem(notification: notification);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends ConsumerWidget {
  final domain.Notification notification;

  const _NotificationItem({
    required this.notification,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(notificationNotifierProvider.notifier);
    final state = ref.watch(notificationNotifierProvider);

    // 通知を既読にする関数
    Future<void> markAsRead() async {
      if (!notification.isRead) {
        try {
          await notifier.markAsRead(notification.id);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('通知の既読処理に失敗しました'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }

    // 通知を承認する関数
    Future<void> acceptNotification() async {
      try {
        await markAsRead();
        await notifier.acceptNotification(notification.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('通知の承認に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    // 通知を拒否する関数
    Future<void> rejectNotification() async {
      try {
        await markAsRead();
        await notifier.rejectNotification(notification.id);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('通知の拒否に失敗しました'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    // ローディング状態のオーバーレイを表示する関数
    Widget buildLoadingOverlay(Widget child) {
      return Stack(
        children: [
          child,
          if (state.isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.1),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return buildLoadingOverlay(
      Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 1,
        child: Container(
          decoration: BoxDecoration(
            border: !notification.isRead
                ? Border(
                    left: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 4,
                    ),
                  )
                : null,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: _buildLeadingIcon(context),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _buildTitle(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _buildSubtitle(),
                  style: TextStyle(
                    fontSize: 14,
                    color: notification.isRead
                        ? Colors.grey[600]
                        : Colors.grey[800],
                  ),
                ),
              ],
            ),
            trailing: notification.status == domain.NotificationStatus.pending
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        onPressed: state.isLoading ? null : acceptNotification,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('承認'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: state.isLoading ? null : rejectNotification,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('拒否'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                          side:
                              BorderSide(color: Theme.of(context).primaryColor),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: notification.status ==
                              domain.NotificationStatus.accepted
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Theme.of(context).primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      notification.status == domain.NotificationStatus.accepted
                          ? '承認済み'
                          : '拒否済み',
                      style: TextStyle(
                        color: notification.status ==
                                domain.NotificationStatus.accepted
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).primaryColor.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
            onTap: state.isLoading ? null : markAsRead,
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
    switch (notification.type) {
      case domain.NotificationType.friend:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_add,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        );
      case domain.NotificationType.groupInvitation:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.group_add,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        );
    }
  }

  String _buildTitle() {
    switch (notification.type) {
      case domain.NotificationType.friend:
        return 'フレンド申請';
      case domain.NotificationType.groupInvitation:
        return 'グループ招待';
    }
  }

  String _buildSubtitle() {
    final fromName =
        notification.sendUserDisplayName ?? notification.sendUserId;
    switch (notification.type) {
      case domain.NotificationType.friend:
        return '$fromNameさんからフレンド申請が届いています';
      case domain.NotificationType.groupInvitation:
        return '$fromNameさんからグループ招待が届いています';
    }
  }
}
