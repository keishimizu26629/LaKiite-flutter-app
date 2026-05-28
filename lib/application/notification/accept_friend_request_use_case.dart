import '../../domain/interfaces/i_notification_repository.dart';

/// 友達申請通知の承認に伴う業務処理を担うUseCase。
class AcceptFriendRequestUseCase {
  const AcceptFriendRequestUseCase({
    required INotificationRepository notificationRepository,
  }) : _notificationRepository = notificationRepository;

  final INotificationRepository _notificationRepository;

  /// 友達申請通知を承認する。
  ///
  /// フレンド関係の更新は Cloud Functions の通知ステータス更新トリガーに任せる。
  Future<void> execute(String notificationId) async {
    final notification =
        await _notificationRepository.getNotification(notificationId);
    if (notification == null) {
      throw Exception('Notification not found');
    }

    await _notificationRepository.acceptNotification(notificationId);
  }
}
