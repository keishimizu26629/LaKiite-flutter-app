import '../../domain/interfaces/i_growth_analytics.dart';
import '../../domain/interfaces/i_notification_repository.dart';
import '../../domain/entity/notification.dart';

/// 友達申請通知の承認に伴う業務処理を担うUseCase。
class AcceptFriendRequestUseCase {
  const AcceptFriendRequestUseCase({
    required INotificationRepository notificationRepository,
    required IGrowthAnalytics growthAnalytics,
  })  : _notificationRepository = notificationRepository,
        _growthAnalytics = growthAnalytics;

  final INotificationRepository _notificationRepository;
  final IGrowthAnalytics _growthAnalytics;

  /// 友達申請通知を承認する。
  ///
  /// フレンド関係の更新は Cloud Functions の通知ステータス更新トリガーに任せる。
  Future<void> execute(String notificationId) async {
    final notification =
        await _notificationRepository.getNotification(notificationId);
    if (notification == null) {
      throw Exception('Notification not found');
    }
    if (notification.type != NotificationType.friend) {
      throw StateError('Notification is not a friend request');
    }

    final didAccept =
        await _notificationRepository.acceptNotification(notificationId);
    if (didAccept) {
      _growthAnalytics.trackFriendRequestAccepted();
    }
  }
}
