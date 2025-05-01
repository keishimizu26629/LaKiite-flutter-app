import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../infrastructure/firebase/push_notification_service.dart';
import '../utils/logger.dart';

/// ユーザーのFCMトークンを管理するサービスクラス
class UserFcmTokenService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PushNotificationService _pushNotificationService;

  UserFcmTokenService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _pushNotificationService = PushNotificationService.instance;

  /// 現在のユーザーのFCMトークンを更新する
  Future<void> updateCurrentUserFcmToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.warning('FCMトークン更新: ユーザーがログインしていません');
        return;
      }

      final token = await _pushNotificationService.refreshToken();
      if (token == null) {
        AppLogger.warning('FCMトークン更新: トークンが取得できませんでした');
        return;
      }

      AppLogger.debug('FCMトークン更新: ユーザーID=${user.uid}, トークン=$token');

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
      });

      AppLogger.debug('FCMトークン更新: 完了');
    } catch (e, stack) {
      AppLogger.error('FCMトークン更新エラー: $e');
      AppLogger.error('スタックトレース: $stack');
    }
  }

  /// ユーザーのFCMトークンを削除する（ログアウト時など）
  Future<void> removeFcmToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.warning('FCMトークン削除: ユーザーがログインしていません');
        return;
      }

      AppLogger.debug('FCMトークン削除: ユーザーID=${user.uid}');

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': FieldValue.delete(),
      });

      AppLogger.debug('FCMトークン削除: 完了');
    } catch (e, stack) {
      AppLogger.error('FCMトークン削除エラー: $e');
      AppLogger.error('スタックトレース: $stack');
    }
  }

  /// 特定のユーザーのFCMトークンを取得する
  Future<String?> getUserFcmToken(String userId) async {
    try {
      AppLogger.debug('FCMトークン取得: ユーザーID=$userId');

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        AppLogger.warning('FCMトークン取得: ユーザーが存在しません - $userId');
        return null;
      }

      final data = doc.data();
      if (data == null) {
        AppLogger.warning('FCMトークン取得: ユーザーデータがありません - $userId');
        return null;
      }

      final token = data['fcmToken'] as String?;
      AppLogger.debug('FCMトークン取得: トークン=$token');

      return token;
    } catch (e, stack) {
      AppLogger.error('FCMトークン取得エラー: $e');
      AppLogger.error('スタックトレース: $stack');
      return null;
    }
  }
}
