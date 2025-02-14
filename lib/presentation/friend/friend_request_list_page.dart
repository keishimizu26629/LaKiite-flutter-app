import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/notification/notification_notifier.dart';
import '../../domain/entity/notification.dart' as domain;

class FriendRequestListPage extends ConsumerWidget {
  const FriendRequestListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('Building FriendRequestListPage');
    final requestsAsyncValue = ref.watch(
      receivedNotificationsByTypeProvider(domain.NotificationType.friend),
    );
    final notifier = ref.watch(notificationNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('友達申請'),
      ),
      body: requestsAsyncValue.when(
        data: (requests) {
          debugPrint('FriendRequestListPage - Received ${requests.length} requests');

          if (requests.isEmpty) {
            debugPrint('FriendRequestListPage - No requests available');
            return const Center(
              child: Text('友達申請はありません'),
            );
          }

          // 未読リクエストを一度だけ既読にする
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (final request in requests.where((r) => !r.isRead)) {
              debugPrint('FriendRequestListPage - Marking request ${request.id} as read');
              notifier.markAsRead(request.id);
            }
          });

          debugPrint('FriendRequestListPage - Building ListView with ${requests.length} items');
          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              debugPrint('FriendRequestListPage - Building card for request ${request.id}');
              return FriendRequestCard(
                request: request,
                onAccept: () {
                  debugPrint('FriendRequestListPage - Accepting request ${request.id}');
                  notifier.acceptNotification(request.id);
                },
                onReject: () {
                  debugPrint('FriendRequestListPage - Rejecting request ${request.id}');
                  notifier.rejectNotification(request.id);
                },
              );
            },
          );
        },
        loading: () {
          debugPrint('FriendRequestListPage - Loading state');
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stack) {
          debugPrint('FriendRequestListPage - Error: $error\n$stack');
          return Center(
            child: Text('エラーが発生しました: $error'),
          );
        },
      ),
    );
  }
}

class FriendRequestCard extends StatelessWidget {
  final domain.Notification request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const FriendRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final senderName = request.sendUserDisplayName ?? request.sendUserId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$senderNameさんから友達申請が届いています',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: request.isRead ? Colors.black87 : Colors.black,
                fontWeight: request.isRead ? FontWeight.normal : FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (request.status == domain.NotificationStatus.pending)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onReject,
                    child: const Text('拒否'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onAccept,
                    child: const Text('承認'),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  request.status == domain.NotificationStatus.accepted ? '承認済み' : '拒否済み',
                  style: TextStyle(
                    color: request.status == domain.NotificationStatus.accepted
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
