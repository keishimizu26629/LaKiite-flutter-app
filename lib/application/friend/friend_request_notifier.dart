import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/friend_request.dart';
import '../../infrastructure/friend_request_repository.dart';
import '../../infrastructure/user_repository.dart';
import '../auth/auth_notifier.dart';

final friendRequestRepositoryProvider = Provider((ref) => FriendRequestRepository());
final userRepositoryProvider = Provider((ref) => UserRepository());

// 未読の友達申請数を監視するProvider
final unreadRequestCountProvider = StreamProvider.autoDispose<int>((ref) {
  debugPrint('Initializing unreadRequestCountProvider');
  final currentUser = ref.watch(authNotifierProvider).value?.user;
  debugPrint('UnreadRequestCount - Current user state: ${currentUser?.toJson()}');

  if (currentUser == null) {
    debugPrint('UnreadRequestCount - No user logged in');
    return Stream.value(0);
  }

  final repository = ref.watch(friendRequestRepositoryProvider);
  debugPrint('UnreadRequestCount - Starting stream for user: ${currentUser.id}');

  return repository.watchReceivedRequests(currentUser.id).map(
    (requests) {
      final unreadCount = requests.where((request) => !request.isRead).length;
      debugPrint('UnreadRequestCount - Processing ${requests.length} requests');
      debugPrint('UnreadRequestCount - Found $unreadCount unread requests');
      for (final request in requests) {
        debugPrint('UnreadRequestCount - Request ${request.id}: isRead=${request.isRead}');
      }
      return unreadCount;
    },
  ).distinct();
});

// 友達申請を表示用に拡張したモデル
class FriendRequestDisplay {
  final FriendRequest request;

  FriendRequestDisplay({
    required this.request,
  });

  String get id => request.id;
  bool get isRead => request.isRead;
  String get senderName => request.sendUserDisplayName ?? '名前なし'; // デフォルト値を設定

  @override
  String toString() => 'FriendRequestDisplay(id: $id, isRead: $isRead, senderName: $senderName)';
}

// 友達申請一覧を監視するProvider
final friendRequestStreamProvider = StreamProvider.autoDispose<List<FriendRequestDisplay>>((ref) {
  debugPrint('Initializing friendRequestStreamProvider');
  final currentUser = ref.watch(authNotifierProvider).value?.user;
  debugPrint('FriendRequestStream - Current user state: ${currentUser?.toJson()}');

  if (currentUser == null) {
    debugPrint('FriendRequestStream - No user logged in');
    return Stream.value([]);
  }

  final repository = ref.watch(friendRequestRepositoryProvider);
  debugPrint('FriendRequestStream - Starting stream for user: ${currentUser.id}');

  return repository.watchReceivedRequests(currentUser.id).map(
    (requests) {
      debugPrint('FriendRequestStream - Processing ${requests.length} requests');
      final displayRequests = requests.map((request) => FriendRequestDisplay(request: request)).toList();
      debugPrint('FriendRequestStream - Display requests: ${displayRequests.join(', ')}');
      return displayRequests;
    },
  ).distinct();
});

final friendRequestNotifierProvider =
    StateNotifierProvider<FriendRequestNotifier, AsyncValue<void>>((ref) {
  final currentUser = ref.watch(authNotifierProvider).value?.user;
  final repository = ref.watch(friendRequestRepositoryProvider);
  return FriendRequestNotifier(repository, currentUser?.id ?? '');
});

class FriendRequestNotifier extends StateNotifier<AsyncValue<void>> {
  final FriendRequestRepository _repository;
  final String _currentUserId;

  FriendRequestNotifier(this._repository, this._currentUserId)
      : super(const AsyncValue.data(null)) {
    debugPrint('FriendRequestNotifier initialized with userId: $_currentUserId');
  }

  Future<void> acceptRequest(String requestId) async {
    debugPrint('Accepting friend request: $requestId');
    try {
      state = const AsyncValue.loading();
      await _repository.acceptFriendRequest(requestId);
      debugPrint('Friend request accepted successfully: $requestId');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('Error accepting friend request: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> rejectRequest(String requestId) async {
    debugPrint('Rejecting friend request: $requestId');
    try {
      state = const AsyncValue.loading();
      await _repository.rejectFriendRequest(requestId);
      debugPrint('Friend request rejected successfully: $requestId');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('Error rejecting friend request: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(String requestId) async {
    debugPrint('Marking friend request as read: $requestId');
    try {
      state = const AsyncValue.loading();
      await _repository.markAsRead(requestId);
      debugPrint('Friend request marked as read successfully: $requestId');
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('Error marking friend request as read: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> hasPendingRequests() async {
    if (_currentUserId.isEmpty) {
      debugPrint('No current user ID available for checking pending requests');
      return false;
    }

    try {
      final requests = await _repository.watchReceivedRequests(_currentUserId).first;
      final hasPending = requests.any((request) => !request.isRead);
      debugPrint('Pending requests check - Total: ${requests.length}, Has unread: $hasPending');
      debugPrint('Pending requests details: ${requests.map((r) => 'id: ${r.id}, isRead: ${r.isRead}').join(', ')}');
      return hasPending;
    } catch (e) {
      debugPrint('Error checking pending requests: $e');
      return false;
    }
  }
}
