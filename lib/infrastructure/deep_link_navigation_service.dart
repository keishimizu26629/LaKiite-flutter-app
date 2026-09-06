import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/deep_link/friend_invite_deep_link.dart';
import '../domain/interfaces/i_growth_analytics.dart';
import '../utils/logger.dart';
import 'deep_link_invite_preferences.dart';
import 'notification_navigation_service.dart';

typedef FriendSearchPageBuilder = Widget Function(
  BuildContext context,
  String searchId,
);

typedef FriendSearchNavigator = Future<void> Function(String searchId);
typedef GrowthAnalyticsClock = DateTime Function();
typedef DeepLinkDebugLogger = void Function(String message);

class DeepLinkNavigationService {
  DeepLinkNavigationService({
    GlobalKey<NavigatorState>? navigatorKey,
    FriendSearchPageBuilder? friendSearchPageBuilder,
    FriendSearchNavigator? friendSearchNavigator,
    DeepLinkInvitePreferences? deepLinkInvitePreferences,
    IGrowthAnalytics? growthAnalytics,
    GrowthAnalyticsClock? now,
    DeepLinkDebugLogger debugLogger = AppLogger.debug,
  })  : navigatorKey =
            navigatorKey ?? NotificationNavigationService.instance.navigatorKey,
        _friendSearchPageBuilder = friendSearchPageBuilder,
        _friendSearchNavigator = friendSearchNavigator,
        _deepLinkInvitePreferences =
            deepLinkInvitePreferences ?? const DeepLinkInvitePreferences(),
        _growthAnalytics = growthAnalytics,
        _now = now ?? DateTime.now,
        _debugLogger = debugLogger;

  static final DeepLinkNavigationService instance = DeepLinkNavigationService();

  final GlobalKey<NavigatorState> navigatorKey;
  final DeepLinkInvitePreferences _deepLinkInvitePreferences;
  final GrowthAnalyticsClock _now;
  final DeepLinkDebugLogger _debugLogger;

  FriendSearchPageBuilder? _friendSearchPageBuilder;
  FriendSearchNavigator? _friendSearchNavigator;
  IGrowthAnalytics? _growthAnalytics;
  final Map<String, DateTime> _recentInviteOpens = {};
  String? _pendingFriendSearchId;
  String? _activeFriendSearchId;
  bool _isNavigationReady = false;

  bool get hasPendingFriendSearchOpen => _pendingFriendSearchId != null;
  bool get isNavigationReady => _isNavigationReady;

  void configureFriendSearchPageBuilder(
    FriendSearchPageBuilder friendSearchPageBuilder,
  ) {
    _friendSearchPageBuilder = friendSearchPageBuilder;
  }

  void configureFriendSearchNavigator(
    FriendSearchNavigator friendSearchNavigator,
  ) {
    _friendSearchNavigator = friendSearchNavigator;
  }

  void configureGrowthAnalytics(IGrowthAnalytics growthAnalytics) {
    _growthAnalytics = growthAnalytics;
  }

  Future<bool> handleReceivedDeepLink(String deepLink) async {
    final friendInvite = FriendInviteDeepLink.tryParse(deepLink);
    if (friendInvite == null) {
      _debugLogger('未対応のDeep Linkを受信しました');
      return false;
    }

    await _deepLinkInvitePreferences.savePendingFriendSearchId(
      friendInvite.searchId,
    );
    _trackFriendInviteOpened(
      searchId: friendInvite.searchId,
      deepLink: deepLink,
    );
    return openFriendSearch(friendInvite.searchId);
  }

  void _trackFriendInviteOpened({
    required String searchId,
    required String deepLink,
  }) {
    final analytics = _growthAnalytics;
    if (analytics == null) {
      return;
    }

    final receivedAt = _now();
    _recentInviteOpens.removeWhere(
      (_, trackedAt) =>
          receivedAt.difference(trackedAt) > const Duration(seconds: 10),
    );
    if (_recentInviteOpens.containsKey(searchId)) {
      return;
    }

    _recentInviteOpens[searchId] = receivedAt;
    analytics.trackFriendInviteOpened(
      transport: _linkTransport(deepLink),
    );
  }

  FriendInviteLinkTransport _linkTransport(String deepLink) {
    final uri = Uri.parse(deepLink.trim());
    if (uri.scheme == 'lakiite' || uri.scheme == 'lakiitedev') {
      return FriendInviteLinkTransport.customScheme;
    }
    if (uri.host.endsWith('.airbridge.io') || uri.host.endsWith('.abr.ge')) {
      return FriendInviteLinkTransport.airbridge;
    }
    return FriendInviteLinkTransport.universalLink;
  }

  Future<bool> markNavigationReady() async {
    _isNavigationReady = true;
    return flushPendingNavigation();
  }

  void markNavigationNotReady() {
    _isNavigationReady = false;
  }

  Future<bool> openFriendSearch(String searchId) async {
    if (!_isNavigationReady) {
      _debugLogger('Deep Link遷移を保留しました: 認証後の画面が未準備');
      _pendingFriendSearchId = searchId;
      await _deepLinkInvitePreferences.savePendingFriendSearchId(searchId);
      return false;
    }

    final friendSearchNavigator = _friendSearchNavigator;
    final friendSearchPageBuilder = _friendSearchPageBuilder;
    if (friendSearchNavigator == null && friendSearchPageBuilder == null) {
      AppLogger.warning('Deep Link遷移を保留しました: 遷移先未設定');
      _pendingFriendSearchId = searchId;
      await _deepLinkInvitePreferences.savePendingFriendSearchId(searchId);
      return false;
    }

    final navigator = navigatorKey.currentState;
    if (friendSearchNavigator == null && navigator == null) {
      _debugLogger('Deep Link遷移を保留しました: Navigator未準備');
      _pendingFriendSearchId = searchId;
      await _deepLinkInvitePreferences.savePendingFriendSearchId(searchId);
      return false;
    }

    if (_activeFriendSearchId == searchId) {
      _debugLogger('表示中のDeep Link遷移をスキップしました');
      await _deepLinkInvitePreferences.clearPendingFriendSearchId();
      return true;
    }

    _pendingFriendSearchId = null;
    _activeFriendSearchId = searchId;
    await _deepLinkInvitePreferences.clearPendingFriendSearchId();

    if (friendSearchNavigator != null) {
      unawaited(
        friendSearchNavigator(searchId).whenComplete(() {
          if (_activeFriendSearchId == searchId) {
            _activeFriendSearchId = null;
          }
        }),
      );
      return true;
    }

    navigator!
        .push(
      MaterialPageRoute<void>(
        builder: (context) => friendSearchPageBuilder!(context, searchId),
      ),
    )
        .whenComplete(() {
      if (_activeFriendSearchId == searchId) {
        _activeFriendSearchId = null;
      }
    });
    return true;
  }

  Future<bool> flushPendingNavigation() async {
    if (!_isNavigationReady) {
      return false;
    }

    final pendingFriendSearchId = _pendingFriendSearchId ??
        await _deepLinkInvitePreferences.getPendingFriendSearchId();
    if (pendingFriendSearchId == null) {
      return false;
    }

    return openFriendSearch(pendingFriendSearchId);
  }
}
