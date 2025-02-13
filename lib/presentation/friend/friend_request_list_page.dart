import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/friend/friend_request_notifier.dart';

class FriendRequestListPage extends ConsumerWidget {
  const FriendRequestListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('Building FriendRequestListPage');
    final requestsAsyncValue = ref.watch(friendRequestStreamProvider);
    final notifier = ref.watch(friendRequestNotifierProvider.notifier);

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
              final requestDisplay = requests[index];
              debugPrint('FriendRequestListPage - Building card for request ${requestDisplay.id}');
              return FriendRequestCard(
                requestDisplay: requestDisplay,
                onAccept: () {
                  debugPrint('FriendRequestListPage - Accepting request ${requestDisplay.id}');
                  notifier.acceptRequest(requestDisplay.id);
                },
                onReject: () {
                  debugPrint('FriendRequestListPage - Rejecting request ${requestDisplay.id}');
                  notifier.rejectRequest(requestDisplay.id);
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
  final FriendRequestDisplay requestDisplay;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const FriendRequestCard({
    super.key,
    required this.requestDisplay,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${requestDisplay.senderName}さんから友達申請が届いています',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
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
            ),
          ],
        ),
      ),
    );
  }
}
