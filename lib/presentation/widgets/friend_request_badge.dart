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
    debugPrint('Building FriendRequestBadge');
    final unreadCountAsyncValue = ref.watch(unreadRequestCountProvider);
    debugPrint('FriendRequestBadge - AsyncValue state: $unreadCountAsyncValue');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        unreadCountAsyncValue.when(
          data: (count) {
            debugPrint('FriendRequestBadge - Unread count: $count');
            if (count == 0) {
              debugPrint('FriendRequestBadge - No unread requests');
              return const SizedBox.shrink();
            }

            return Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
          loading: () {
            debugPrint('FriendRequestBadge - Loading state');
            return const SizedBox.shrink();
          },
          error: (error, stack) {
            debugPrint('FriendRequestBadge - Error: $error\n$stack');
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
