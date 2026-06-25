import 'package:flutter/material.dart';

import '../domain/deep_link/friend_invite_deep_link.dart';
import '../utils/logger.dart';
import 'deep_link_invite_preferences.dart';
import 'notification_navigation_service.dart';

typedef FriendSearchPageBuilder = Widget Function(
  BuildContext context,
  String searchId,
);

class DeepLinkNavigationService {
  DeepLinkNavigationService({
    GlobalKey<NavigatorState>? navigatorKey,
    FriendSearchPageBuilder? friendSearchPageBuilder,
    DeepLinkInvitePreferences? deepLinkInvitePreferences,
  })  : navigatorKey =
            navigatorKey ?? NotificationNavigationService.instance.navigatorKey,
        _friendSearchPageBuilder = friendSearchPageBuilder,
        _deepLinkInvitePreferences =
            deepLinkInvitePreferences ?? const DeepLinkInvitePreferences();

  static final DeepLinkNavigationService instance = DeepLinkNavigationService();

  final GlobalKey<NavigatorState> navigatorKey;
  final DeepLinkInvitePreferences _deepLinkInvitePreferences;

  FriendSearchPageBuilder? _friendSearchPageBuilder;
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

  Future<bool> handleReceivedDeepLink(String deepLink) async {
    final friendInvite = FriendInviteDeepLink.tryParse(deepLink);
    if (friendInvite == null) {
      AppLogger.debug('未対応のDeep Linkを受信しました: $deepLink');
      return false;
    }

    await _deepLinkInvitePreferences.savePendingFriendSearchId(
      friendInvite.searchId,
    );
    return openFriendSearch(friendInvite.searchId);
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
      AppLogger.debug('Deep Link遷移を保留しました: 認証後の画面が未準備');
      _pendingFriendSearchId = searchId;
      await _deepLinkInvitePreferences.savePendingFriendSearchId(searchId);
      return false;
    }

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      AppLogger.debug('Deep Link遷移を保留しました: Navigator未準備');
      _pendingFriendSearchId = searchId;
      await _deepLinkInvitePreferences.savePendingFriendSearchId(searchId);
      return false;
    }

    final friendSearchPageBuilder = _friendSearchPageBuilder;
    if (friendSearchPageBuilder == null) {
      AppLogger.warning('Deep Link遷移を保留しました: builder未設定');
      _pendingFriendSearchId = searchId;
      await _deepLinkInvitePreferences.savePendingFriendSearchId(searchId);
      return false;
    }

    if (_activeFriendSearchId == searchId) {
      AppLogger.debug('表示中のDeep Link遷移をスキップしました: $searchId');
      await _deepLinkInvitePreferences.clearPendingFriendSearchId();
      return true;
    }

    _pendingFriendSearchId = null;
    _activeFriendSearchId = searchId;
    await _deepLinkInvitePreferences.clearPendingFriendSearchId();
    navigator
        .push(
      MaterialPageRoute<void>(
        builder: (context) => friendSearchPageBuilder(context, searchId),
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
