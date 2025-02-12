import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/friend/friend_request_notifier.dart';
import '../../domain/entity/friend_request.dart';

class FriendRequestListPage extends ConsumerWidget {
  const FriendRequestListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsyncValue = ref.watch(friendRequestStreamProvider);
    final notifier = ref.watch(friendRequestNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('友達申請'),
      ),
      body: requestsAsyncValue.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Text('友達申請はありません'),
            );
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return FriendRequestCard(
                request: request,
                onAccept: () => notifier.acceptRequest(request.id),
                onReject: () => notifier.rejectRequest(request.id),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }
}

class FriendRequestCard extends StatelessWidget {
  final FriendRequest request;
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '友達申請が届いています',
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
