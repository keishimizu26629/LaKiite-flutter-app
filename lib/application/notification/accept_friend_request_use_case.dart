import '../../domain/entity/notification.dart';
import '../../domain/interfaces/i_notification_repository.dart';
import '../../domain/interfaces/i_user_repository.dart';

/// 友達申請通知の承認に伴う業務処理を担うUseCase。
class AcceptFriendRequestUseCase {
  const AcceptFriendRequestUseCase({
    required INotificationRepository notificationRepository,
    required IUserRepository userRepository,
  })  : _notificationRepository = notificationRepository,
        _userRepository = userRepository;

  final INotificationRepository _notificationRepository;
  final IUserRepository _userRepository;

  /// 友達申請通知を承認する。
  ///
  /// 申請元または受信者が存在しない場合は友達関係を作らず、通知を期限切れにする。
  Future<void> execute(String notificationId) async {
    final notification =
        await _notificationRepository.getNotification(notificationId);
    if (notification == null) {
      throw Exception('Notification not found');
    }

    if (notification.type != NotificationType.friend) {
      await _notificationRepository.acceptNotification(notificationId);
      return;
    }

    final receiver = await _userRepository.getUser(notification.receiveUserId);
    final sender = await _userRepository.getUser(notification.sendUserId);
    if (receiver == null || sender == null) {
      await _notificationRepository.expireNotification(notificationId);
      return;
    }

    await _addFriendIfNeeded(
      userId: receiver.id,
      friendId: sender.id,
    );
    await _addFriendIfNeeded(
      userId: sender.id,
      friendId: receiver.id,
    );
    await _notificationRepository.acceptNotification(notificationId);
  }

  Future<void> _addFriendIfNeeded({
    required String userId,
    required String friendId,
  }) async {
    final user = await _userRepository.getUser(userId);
    if (user == null || user.friends.contains(friendId)) {
      return;
    }

    await _userRepository.addToList(userId, friendId);
  }
}
