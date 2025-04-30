import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../utils/logger.dart';
import '../../infrastructure/user_fcm_token_service.dart';
import '../../config/app_config.dart';

/// Firebase Cloud Messagingを使用してプッシュ通知を送信するサービスクラス
///
/// Cloud FunctionsにPOSTリクエストを送信して通知を配信します
/// 実際の実装ではCloud Functions側で認証とセキュリティチェックを行う必要があります
class PushNotificationSender {
  final String _cloudFunctionUrl;
  final UserFcmTokenService _fcmTokenService;

  /// コンストラクタ
  ///
  /// [cloudFunctionUrl] 通知送信用のCloud Function URL（開発/本番環境で切り替え）
  PushNotificationSender({
    String? cloudFunctionUrl,
    UserFcmTokenService? fcmTokenService,
  })  : _cloudFunctionUrl =
            cloudFunctionUrl ?? AppConfig.instance.pushNotificationUrl,
        _fcmTokenService = fcmTokenService ?? UserFcmTokenService();

  /// 友達申請通知を送信する
  ///
  /// [toUserId] 通知の送信先ユーザーID
  /// [fromUserId] 送信元ユーザーID
  /// [fromUserName] 送信元ユーザー名
  Future<bool> sendFriendRequestNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
  }) async {
    try {
      // 送信先ユーザーのFCMトークンを取得
      final token = await _fcmTokenService.getUserFcmToken(toUserId);
      if (token == null) {
        AppLogger.warning('プッシュ通知送信エラー: 宛先ユーザーのFCMトークンがありません - $toUserId');
        return false;
      }

      // 通知データを準備
      final notificationData = {
        'token': token,
        'notification': {
          'title': '友達申請が届きました',
          'body': '$fromUserNameさんから友達申請が届いています',
        },
        'data': {
          'type': 'friend_request',
          'fromUserId': fromUserId,
          'toUserId': toUserId,
          'fromUserName': fromUserName,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      };

      // Cloud Functionに通知データを送信
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(notificationData),
      );

      // レスポンスを確認
      if (response.statusCode == 200) {
        AppLogger.debug('プッシュ通知送信成功: ${response.body}');
        return true;
      } else {
        AppLogger.error(
            'プッシュ通知送信エラー: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('プッシュ通知送信例外: $e');
      AppLogger.error('スタックトレース: $stack');
      return false;
    }
  }

  /// グループ招待通知を送信する
  ///
  /// [toUserId] 通知の送信先ユーザーID
  /// [fromUserId] 招待者ユーザーID
  /// [fromUserName] 招待者ユーザー名
  /// [groupId] グループID
  /// [groupName] グループ名
  Future<bool> sendGroupInvitationNotification({
    required String toUserId,
    required String fromUserId,
    required String fromUserName,
    required String groupId,
    required String groupName,
  }) async {
    try {
      // 送信先ユーザーのFCMトークンを取得
      final token = await _fcmTokenService.getUserFcmToken(toUserId);
      if (token == null) {
        AppLogger.warning('プッシュ通知送信エラー: 宛先ユーザーのFCMトークンがありません - $toUserId');
        return false;
      }

      // 通知データを準備
      final notificationData = {
        'token': token,
        'notification': {
          'title': 'グループ招待が届きました',
          'body': '$fromUserNameさんから「$groupName」グループへの招待が届いています',
        },
        'data': {
          'type': 'group_invitation',
          'fromUserId': fromUserId,
          'toUserId': toUserId,
          'fromUserName': fromUserName,
          'groupId': groupId,
          'groupName': groupName,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      };

      // Cloud Functionに通知データを送信
      final response = await http.post(
        Uri.parse(_cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(notificationData),
      );

      // レスポンスを確認
      if (response.statusCode == 200) {
        AppLogger.debug('プッシュ通知送信成功: ${response.body}');
        return true;
      } else {
        AppLogger.error(
            'プッシュ通知送信エラー: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('プッシュ通知送信例外: $e');
      AppLogger.error('スタックトレース: $stack');
      return false;
    }
  }
}
