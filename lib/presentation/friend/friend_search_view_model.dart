import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/notification.dart' as domain;
import '../../domain/interfaces/i_user_repository.dart';
import '../../infrastructure/notification_repository.dart';
import '../../application/auth/auth_notifier.dart' as auth;
import '../../presentation/presentation_provider.dart';
import '../../utils/logger.dart';

class SearchUserModel {
  const SearchUserModel({
    required this.id,
    required this.displayName,
    required this.searchId,
    required this.iconUrl,
    this.shortBio,
    this.hasPendingRequest = false,
  });

  final String id;
  final String displayName;
  final String searchId;
  final String iconUrl;
  final String? shortBio;
  final bool hasPendingRequest;
}

final friendSearchViewModelProvider =
    StateNotifierProvider<FriendSearchViewModel, AsyncValue<SearchUserModel?>>(
        (ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  final notificationRepository = NotificationRepository();
  final currentUser = ref.watch(auth.authNotifierProvider).value?.user;
  return FriendSearchViewModel(
    userRepository,
    notificationRepository,
    currentUser?.id ?? '',
    currentUser?.publicProfile.displayName ?? '',
  );
});

class FriendSearchViewModel
    extends StateNotifier<AsyncValue<SearchUserModel?>> {
  FriendSearchViewModel(
    this._userRepository,
    this._notificationRepository,
    this._currentUserId,
    this._currentUserDisplayName,
  ) : super(const AsyncValue.data(null));

  String? _message;
  String? get message => _message;
  final IUserRepository _userRepository;
  final NotificationRepository _notificationRepository;
  final String _currentUserId;
  final String _currentUserDisplayName;

  Future<void> searchUser(String searchId) async {
    try {
      _message = null;
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

      // 友達申請の状態を確認(送信済みまたは受信済み)
      bool hasPending = false;
      try {
        // 自分が送信した申請を確認
        final hasSentPending =
            await _notificationRepository.hasPendingFriendRequest(
          _currentUserId,
          user.id,
        );

        // 相手から受信した申請を確認
        final hasReceivedPending =
            await _notificationRepository.hasPendingFriendRequest(
          user.id,
          _currentUserId,
        );

        hasPending = hasSentPending || hasReceivedPending;
      } catch (e) {
        AppLogger.error('Friend request check error: $e');
      }

      // SearchUserModelを作成
      final searchUser = SearchUserModel(
        id: user.id,
        displayName: user.displayName,
        searchId: user.searchId,
        iconUrl: user.iconUrl ?? '',
        shortBio: user.shortBio,
        hasPendingRequest: hasPending,
      );

      state = AsyncValue.data(searchUser);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> sendFriendRequest(String toUserId) async {
    try {
      if (_currentUserId.isEmpty) {
        throw Exception('ログインが必要です');
      }

      if (state.value == null) {
        throw Exception('ユーザー情報が見つかりません');
      }

      AppLogger.info('👥 友達申請を送信開始: $_currentUserId → $toUserId');

      final notification = domain.Notification.createFriendRequest(
        fromUserId: _currentUserId,
        toUserId: toUserId,
        fromUserDisplayName: _currentUserDisplayName,
        toUserDisplayName: state.value!.displayName,
      );

      // Firestoreに通知を保存（Cloud Functionsのトリガーが自動実行される）
      await _notificationRepository.createNotification(notification);

      AppLogger.info(
          '✅ 友達申請通知をFirestoreに保存完了 - Cloud Functionsが自動でプッシュ通知を送信します');

      _message = '友達申請を送信しました';
      state = const AsyncValue.data(null); // 検索結果をクリア
    } catch (e) {
      AppLogger.error('❌ 友達申請送信エラー: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // 状態をリセットするメソッド
  void resetState() {
    _message = null;
    state = const AsyncValue.data(null);
  }
}
