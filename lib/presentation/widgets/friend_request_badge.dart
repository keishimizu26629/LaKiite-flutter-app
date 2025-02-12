import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/friend/friend_request_notifier.dart';

class FriendRequestBadge extends ConsumerWidget {
  final Widget child;

  const FriendRequestBadge({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsyncValue = ref.watch(friendRequestStreamProvider);

    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        requestsAsyncValue.when(
          data: (requests) {
            final hasUnread = requests.any((request) => !request.isRead);
            if (!hasUnread) return const SizedBox.shrink();

            return Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Text(
                  requests.where((request) => !request.isRead).length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
