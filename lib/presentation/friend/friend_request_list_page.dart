import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../application/notification/notification_notifier.dart';
import '../../domain/entity/notification.dart' as domain;
import '../../utils/logger.dart';
import '../../presentation/presentation_provider.dart';

class FriendRequestListPage extends ConsumerWidget {
  const FriendRequestListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppLogger.debug('Building FriendRequestListPage');
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
          if (requests.isNotEmpty) {
            AppLogger.debug(
                'FriendRequestListPage - Received ${requests.length} requests');

            // 未読リクエストを一度だけ既読にする
            WidgetsBinding.instance.addPostFrameCallback((_) {
              for (final request in requests.where((r) => !r.isRead)) {
                AppLogger.debug(
                    'FriendRequestListPage - Marking request ${request.id} as read');
                notifier.markAsRead(request.id);
              }
            });

            return _buildRequestList(context, ref, requests);
          }
          AppLogger.debug('FriendRequestListPage - No requests available');
          return _buildEmptyState();
        },
        loading: () {
          AppLogger.debug('FriendRequestListPage - Loading state');
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        error: (error, stack) {
          AppLogger.error('FriendRequestListPage - Error: $error\n$stack');
          return Center(
            child: Text('エラーが発生しました: $error'),
          );
        },
      ),
    );
  }

  Widget _buildRequestList(
    BuildContext context,
    WidgetRef ref,
    List<domain.Notification> requests,
  ) {
    final notifier = ref.watch(notificationNotifierProvider.notifier);
    AppLogger.debug(
        'FriendRequestListPage - Building ListView with ${requests.length} items');
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        AppLogger.debug(
            'FriendRequestListPage - Building card for request ${request.id}');
        return FriendRequestCard(
          request: request,
          onAccept: () {
            AppLogger.debug(
                'FriendRequestListPage - Accepting request ${request.id}');
            notifier.acceptNotification(request.id).then((_) {
              // フレンド申請承認後にフレンドリストを更新
              ref.invalidate(userFriendsProvider);
            });
          },
          onReject: () {
            AppLogger.debug(
                'FriendRequestListPage - Rejecting request ${request.id}');
            notifier.rejectNotification(request.id);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('友達申請はありません'),
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
                    fontWeight:
                        request.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
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
                  request.status == domain.NotificationStatus.accepted
                      ? '承認済み'
                      : '拒否済み',
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
