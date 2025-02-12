import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/user.dart';
import '../../domain/entity/friend_request.dart';
import '../../domain/interfaces/i_user_repository.dart';
import '../../infrastructure/friend_request_repository.dart';
import '../../application/auth/auth_notifier.dart' as auth;

final friendSearchViewModelProvider =
    StateNotifierProvider<FriendSearchViewModel, AsyncValue<SearchUserModel?>>((ref) {
  final userRepository = ref.watch(auth.userRepositoryProvider);
  final friendRequestRepository = FriendRequestRepository();
  final currentUser = ref.watch(auth.authNotifierProvider).value?.user;
  return FriendSearchViewModel(
    userRepository,
    friendRequestRepository,
    currentUser?.id ?? '',
  );
});

class FriendSearchViewModel extends StateNotifier<AsyncValue<SearchUserModel?>> {
  final IUserRepository _userRepository;
  final FriendRequestRepository _friendRequestRepository;
  final String _currentUserId;

  FriendSearchViewModel(
    this._userRepository,
    this._friendRequestRepository,
    this._currentUserId,
  ) : super(const AsyncValue.data(null));

  Future<void> searchUser(String searchId) async {
    try {
      state = const AsyncValue.loading();

      // 自分自身は検索対象外
      if (_currentUserId.isEmpty) {
        throw Exception('ログインが必要です');
      }

      final user = await _userRepository.findBySearchId(searchId);
      if (user == null) {
        throw Exception('ユーザーが見つかりません');
      }

      if (user.id == _currentUserId) {
        throw Exception('自分自身は友達に追加できません');
      }

      // SearchUserModelを作成(iconUrlがnullの場合は空文字列を設定)
      final searchUser = SearchUserModel(
        id: user.id,
        displayName: user.displayName,
        searchId: user.searchId,
        iconUrl: user.iconUrl ?? '',
      );

      state = AsyncValue.data(searchUser);

      // 友達申請のチェックは非同期で行い、エラーがあっても検索結果は表示する
      try {
        final hasPending = await _friendRequestRepository.hasPendingRequest(
          _currentUserId,
          user.id,
        );
        if (hasPending) {
          throw Exception('既に友達申請を送信済みです');
        }
      } catch (e) {
        print('Friend request check error: $e');
        // エラーは表示するが、検索結果は維持する
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> sendFriendRequest(String toUserId) async {
    try {
      if (_currentUserId.isEmpty) {
        throw Exception('ログインが必要です');
      }

      final request = FriendRequest.create(
        fromUserId: _currentUserId,
        toUserId: toUserId,
      );

      await _friendRequestRepository.createFriendRequest(request);
      state = const AsyncValue.data(null); // 検索結果をクリア
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // 状態をリセットするメソッド
  void resetState() {
    state = const AsyncValue.data(null);
  }
}
