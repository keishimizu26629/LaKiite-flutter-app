import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../../utils/logger.dart';
import '../../infrastructure/user_fcm_token_service.dart';
import '../../config/app_config.dart';

/// Firebase Cloud Messagingを使用してプッシュ通知を送信するサービスクラス
///
/// Cloud FunctionsにPOSTリクエストを送信して通知を配信します
/// 実際の実装ではCloud Functions側で認証とセキュリティチェックを行う必要があります
class PushNotificationSender {
  factory PushNotificationSender({
    String? cloudFunctionUrl,
    UserFcmTokenService? fcmTokenService,
    Future<List<String>> Function(String userId)? tokenResolver,
    http.Client? httpClient,
  }) {
    final resolvedTokenResolver = tokenResolver ??
        (fcmTokenService ?? UserFcmTokenService()).getUserFcmTokens;
    return PushNotificationSender._(
      cloudFunctionUrl ?? AppConfig.instance.pushNotificationUrl,
      resolvedTokenResolver,
      httpClient ?? http.Client(),
    );
  }

  PushNotificationSender._(
    this._cloudFunctionUrl,
    this._tokenResolver,
    this._httpClient,
  );

  final String _cloudFunctionUrl;
  final Future<List<String>> Function(String userId) _tokenResolver;
  final http.Client _httpClient;
  static const int _tokenPreviewLength = 20;

  Future<bool> sendFriendRequestNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
  }) async {
    AppLogger.info('👥 友達申請通知の送信を開始');
    AppLogger.info('👥 送信先: $toUserId, 送信元: $fromUserId ($fromUserName)');

    return _sendNotification(
      logContext: '友達申請通知',
      toUserId: toUserId,
      notificationBody: {
        'title': '友達申請が届きました',
        'body': '$fromUserNameさんから友達申請が届いています',
      },
      data: {
        'type': 'friend_request',
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromUserName': fromUserName,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Future<bool> sendGroupInvitationNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String groupId,
    required String groupName,
  }) async {
    return _sendNotification(
      logContext: 'グループ招待通知',
      toUserId: toUserId,
      notificationBody: {
        'title': 'グループ招待が届きました',
        'body': '$fromUserNameさんから「$groupName」グループへの招待が届いています',
      },
      data: {
        'type': 'group_invitation',
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromUserName': fromUserName,
        'groupId': groupId,
        'groupName': groupName,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Future<bool> sendReactionNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String scheduleId,
    required String interactionId,
  }) async {
    return _sendNotification(
      logContext: 'リアクション通知',
      toUserId: toUserId,
      notificationBody: {
        'title': '新しいリアクション',
        'body': '$fromUserNameさんがあなたの投稿にリアクションしました',
      },
      data: {
        'type': 'reaction',
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromUserName': fromUserName,
        'scheduleId': scheduleId,
        'interactionId': interactionId,
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Future<bool> sendCommentNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String scheduleId,
    required String interactionId,
    String? commentContent,
  }) async {
    final commentPreview = commentContent != null && commentContent.isNotEmpty
        ? (commentContent.length > 50
            ? '${commentContent.substring(0, 47)}...'
            : commentContent)
        : '';

    return _sendNotification(
      logContext: 'コメント通知',
      toUserId: toUserId,
      notificationBody: {
        'title': '新しいコメント',
        'body':
            '$fromUserNameさんがあなたの投稿にコメントしました${commentPreview.isNotEmpty ? ': $commentPreview' : ''}',
      },
      data: {
        'type': 'comment',
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'fromUserName': fromUserName,
        'scheduleId': scheduleId,
        'interactionId': interactionId,
        'commentContent': commentContent ?? '',
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Future<bool> _sendNotification({
    required String logContext,
    required String toUserId,
    required Map<String, dynamic> notificationBody,
    required Map<String, dynamic> data,
  }) async {
    try {
      final tokens = await _fetchRecipientTokens(toUserId, logContext);
      if (tokens.isEmpty) {
        return false;
      }

      var successCount = 0;
      for (final token in tokens) {
        final payload = {
          'token': token,
          'notification': notificationBody,
          'data': data,
        };

        final didSend = await _postNotification(payload, logContext, token);
        if (didSend) {
          successCount++;
        }
      }

      if (successCount == 0) {
        AppLogger.error('$logContext 送信失敗: 全${tokens.length}件のトークンで失敗');
        return false;
      }

      if (successCount < tokens.length) {
        AppLogger.warning(
            '$logContext 一部送信成功: $successCount/${tokens.length}件');
      } else {
        AppLogger.debug('$logContext 全トークン送信成功: $successCount件');
      }

      return true;
    } catch (e, stack) {
      AppLogger.error('$logContext 送信例外: $e');
      AppLogger.error('スタックトレース: $stack');
      return false;
    }
  }

  Future<List<String>> _fetchRecipientTokens(
      String userId, String logContext) async {
    AppLogger.info('🔍 $logContext: 宛先ユーザーのFCMトークン一覧を取得中...');
    final tokens = _deduplicateTokens(await _tokenResolver(userId));
    if (tokens.isEmpty) {
      AppLogger.warning('❌ $logContext: 宛先ユーザーのFCMトークンがありません - $userId');
      return const [];
    }

    AppLogger.info(
        '✅ $logContext: FCMトークン取得成功: ${tokens.length}件 (${tokens.map(_previewToken).join(', ')})');
    return tokens;
  }

  Future<bool> _postNotification(
    Map<String, dynamic> payload,
    String logContext,
    String token,
  ) async {
    final response = await _httpClient.post(
      Uri.parse(_cloudFunctionUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      AppLogger.debug(
          '$logContext 送信成功: ${_previewToken(token)} ${response.body}');
      return true;
    }

    AppLogger.error(
        '$logContext 送信エラー: ${_previewToken(token)} ${response.statusCode} - ${response.body}');
    return false;
  }

  List<String> _deduplicateTokens(List<String> tokens) {
    return tokens.where((token) => token.isNotEmpty).toSet().toList();
  }

  String _previewToken(String token) {
    if (token.length <= _tokenPreviewLength) {
      return token;
    }
    final previewLength = math.min(token.length, _tokenPreviewLength);
    return '${token.substring(0, previewLength)}...';
  }
}
