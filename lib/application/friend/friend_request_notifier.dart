import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/friend_request.dart';
import '../../infrastructure/friend_request_repository.dart';
import '../auth/auth_notifier.dart';

final friendRequestRepositoryProvider = Provider((ref) => FriendRequestRepository());

final friendRequestStreamProvider = StreamProvider<List<FriendRequest>>((ref) {
  final currentUser = ref.watch(authNotifierProvider).value?.user;
  if (currentUser == null) {
    return Stream.value([]);
  }

  final repository = ref.watch(friendRequestRepositoryProvider);
  return repository.watchReceivedRequests(currentUser.id);
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
      : super(const AsyncValue.data(null));

  Future<void> acceptRequest(String requestId) async {
    try {
      state = const AsyncValue.loading();
      await _repository.acceptFriendRequest(requestId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> rejectRequest(String requestId) async {
    try {
      state = const AsyncValue.loading();
      await _repository.rejectFriendRequest(requestId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(String requestId) async {
    try {
      state = const AsyncValue.loading();
      await _repository.markAsRead(requestId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> hasPendingRequests() async {
    if (_currentUserId.isEmpty) return false;

    try {
      final requests = await _repository.watchReceivedRequests(_currentUserId).first;
      return requests.any((request) => !request.isRead);
    } catch (e) {
      return false;
    }
  }
}
