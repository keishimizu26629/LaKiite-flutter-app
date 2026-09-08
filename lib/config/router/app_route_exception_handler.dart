import 'dart:async';

import '../../domain/deep_link/friend_invite_deep_link.dart';
import '../../utils/logger.dart';

/// ルーター未解決のURLを招待処理へ委譲し、未対応ならスプラッシュへ戻す。
///
/// URLは遷移処理だけに渡し、ログには処理結果のみを記録する。
/// Airbridge短縮リンクはSDKによる解決を待つ。
void handleAppRouteException(
  Uri uri, {
  required Future<bool> Function(String) handleDeepLink,
  required void Function() goToSplash,
  void Function(String) logInfo = AppLogger.info,
  void Function(String) logWarning = AppLogger.warning,
}) {
  final location = uri.toString();
  final friendInviteDeepLink = FriendInviteDeepLink.tryParse(location);
  if (friendInviteDeepLink != null) {
    logInfo('GoRouterで受信したDeep Linkを専用処理へ委譲しました');
    unawaited(handleDeepLink(location));
    return;
  }

  if (FriendInviteDeepLink.isSupportedAirbridgeLink(location)) {
    logInfo('Airbridge LinkのSDK解決を待機します');
    return;
  }

  logWarning('GoRouter例外を検出しました');
  goToSplash();
}
