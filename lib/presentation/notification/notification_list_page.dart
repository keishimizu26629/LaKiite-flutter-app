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

final notificationFilterProvider = StateProvider<NotificationFilter>((ref) => NotificationFilter.all);

class NotificationListPage extends ConsumerWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsyncValue = ref.watch(receivedNotificationsProvider);

    final selectedFilter = ref.watch(notificationFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: NotificationFilter.values.map((filter) {
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        ref.read(notificationFilterProvider.notifier).state = filter;
                      }
                    },
                  ),
                );
              }).toList(),
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

  List<domain.Notification> _filterNotifications(List<domain.Notification> notifications) {
    switch (filter) {
      case NotificationFilter.all:
        return notifications;
      case NotificationFilter.unread:
        return notifications.where((notification) => !notification.isRead).toList();
      case NotificationFilter.pending:
        return notifications.where((notification) =>
          notification.status == domain.NotificationStatus.pending).toList();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return asyncValue.when(
      data: (notifications) {
        final filteredNotifications = _filterNotifications(notifications);
        if (filteredNotifications.isEmpty) {
          return Center(
            child: Text(
              filter == NotificationFilter.all
                ? '通知はありません'
                : '${filter.label}の通知はありません',
            ),
          );
        }

        return ListView.builder(
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
        child: Text('エラーが発生しました: $error'),
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

    // 通知を既読にする関数
    Future<void> markAsRead() async {
      if (!notification.isRead) {
        await notifier.markAsRead(notification.id);
      }
    }

    // 通知を承認する関数
    Future<void> acceptNotification() async {
      await markAsRead();
      await notifier.acceptNotification(notification.id);
    }

    // 通知を拒否する関数
    Future<void> rejectNotification() async {
      await markAsRead();
      await notifier.rejectNotification(notification.id);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: notification.isRead ? null : Colors.yellow[50],
      child: Stack(
        children: [
          ListTile(
            leading: _buildLeadingIcon(),
            title: Text(_buildTitle()),
            subtitle: Text(
              _buildSubtitle(),
              style: TextStyle(
                color: notification.isRead ? Colors.grey : Colors.black87,
              ),
            ),
            trailing: notification.status == domain.NotificationStatus.pending
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: acceptNotification,
                        color: Colors.green,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: rejectNotification,
                        color: Colors.red,
                      ),
                    ],
                  )
                : Text(
                    notification.status == domain.NotificationStatus.accepted ? '承認済み' : '拒否済み',
                    style: TextStyle(
                      color: notification.status == domain.NotificationStatus.accepted
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
            onTap: markAsRead,
          ),
          if (!notification.isRead)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon() {
    switch (notification.type) {
      case domain.NotificationType.friend:
        return const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.person_add, color: Colors.white),
        );
      case domain.NotificationType.groupInvitation:
        return const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.group_add, color: Colors.white),
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
    final fromName = notification.sendUserDisplayName ?? notification.sendUserId;
    switch (notification.type) {
      case domain.NotificationType.friend:
        return '$fromNameさんからフレンド申請が届いています';
      case domain.NotificationType.groupInvitation:
        return '$fromNameさんからグループ招待が届いています';
    }
  }
}
