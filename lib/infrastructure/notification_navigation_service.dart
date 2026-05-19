import 'package:flutter/material.dart';

import '../utils/logger.dart';

typedef NotificationListPageBuilder = WidgetBuilder;

class NotificationNavigationService {
  NotificationNavigationService({
    GlobalKey<NavigatorState>? navigatorKey,
    NotificationListPageBuilder? notificationListBuilder,
  })  : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
        _notificationListBuilder = notificationListBuilder;

  static final NotificationNavigationService instance =
      NotificationNavigationService();

  final GlobalKey<NavigatorState> navigatorKey;
  NotificationListPageBuilder? _notificationListBuilder;

  bool _hasPendingNotificationListOpen = false;

  bool get hasPendingNotificationListOpen => _hasPendingNotificationListOpen;

  void configureNotificationListBuilder(
    NotificationListPageBuilder notificationListBuilder,
  ) {
    _notificationListBuilder = notificationListBuilder;
  }

  void openNotificationList() {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      AppLogger.debug('通知一覧への遷移を保留しました: Navigator未準備');
      _hasPendingNotificationListOpen = true;
      return;
    }

    final notificationListBuilder = _notificationListBuilder;
    if (notificationListBuilder == null) {
      AppLogger.warning('通知一覧への遷移を保留しました: builder未設定');
      _hasPendingNotificationListOpen = true;
      return;
    }

    _hasPendingNotificationListOpen = false;
    navigator.push(
      MaterialPageRoute(
        builder: notificationListBuilder,
      ),
    );
  }

  void flushPendingNavigation() {
    if (!_hasPendingNotificationListOpen) {
      return;
    }
    openNotificationList();
  }
}
