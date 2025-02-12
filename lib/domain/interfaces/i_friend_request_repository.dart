import '../entity/friend_request.dart';

abstract class IFriendRequestRepository {
  /// 友達申請を作成
  Future<void> createFriendRequest(FriendRequest request);

  /// 友達申請を更新
  Future<void> updateFriendRequest(FriendRequest request);

  /// 友達申請を取得
  Future<FriendRequest?> getFriendRequest(String requestId);

  /// ユーザーの受信した友達申請を取得
  Stream<List<FriendRequest>> watchReceivedRequests(String userId);

  /// ユーザーの送信した友達申請を取得
  Stream<List<FriendRequest>> watchSentRequests(String userId);

  /// 2人のユーザー間の保留中の友達申請を確認
  Future<bool> hasPendingRequest(String fromUserId, String toUserId);

  /// 友達申請を承認
  Future<void> acceptFriendRequest(String requestId);

  /// 友達申請を拒否
  Future<void> rejectFriendRequest(String requestId);

  /// 友達申請を既読にする
  Future<void> markAsRead(String requestId);
}
