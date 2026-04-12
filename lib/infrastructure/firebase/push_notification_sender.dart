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
  PushNotificationSender({
    String? cloudFunctionUrl,
    UserFcmTokenService? fcmTokenService,
  })  : _cloudFunctionUrl =
            cloudFunctionUrl ?? AppConfig.instance.pushNotificationUrl,
        _fcmTokenService = fcmTokenService ?? UserFcmTokenService();
  final String _cloudFunctionUrl;
  final UserFcmTokenService _fcmTokenService;
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
      final token = await _fetchRecipientToken(toUserId, logContext);
      if (token == null) {
        return false;
      }

      final payload = {
        'token': token,
        'notification': notificationBody,
        'data': data,
      };

      return await _postNotification(payload, logContext);
    } catch (e, stack) {
      AppLogger.error('$logContext 送信例外: $e');
      AppLogger.error('スタックトレース: $stack');
      return false;
    }
  }

  Future<String?> _fetchRecipientToken(String userId, String logContext) async {
    AppLogger.info('🔍 $logContext: 宛先ユーザーのFCMトークンを取得中...');
    final token = await _fcmTokenService.getUserFcmToken(userId);
    if (token == null) {
      AppLogger.warning('❌ $logContext: 宛先ユーザーのFCMトークンがありません - $userId');
      return null;
    }
    AppLogger.info('✅ $logContext: FCMトークン取得成功: ${_previewToken(token)}');
    return token;
  }

  Future<bool> _postNotification(
      Map<String, dynamic> payload, String logContext) async {
    final response = await http.post(
      Uri.parse(_cloudFunctionUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      AppLogger.debug('$logContext 送信成功: ${response.body}');
      return true;
    }

    AppLogger.error(
        '$logContext 送信エラー: ${response.statusCode} - ${response.body}');
    return false;
  }

  String _previewToken(String token) {
    if (token.length <= _tokenPreviewLength) {
      return token;
    }
    final previewLength = math.min(token.length, _tokenPreviewLength);
    return '${token.substring(0, previewLength)}...';
  }
}
