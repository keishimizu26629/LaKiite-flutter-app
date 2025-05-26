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

      // Firebase Functionsが参照する場所（users/{userId}直下）に保存
      // updateではなくsetを使用してドキュメントが存在しない場合でも確実に保存
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));

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

      try {
        // Firestoreのユーザードキュメントを取得して存在確認
        final docRef = _firestore.collection('users').doc(user.uid);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          AppLogger.warning('FCMトークン削除: ユーザードキュメントが存在しません');
          return;
        }

        // fcmTokenフィールドが存在するか確認
        final data = docSnapshot.data();
        if (data == null || !data.containsKey('fcmToken')) {
          AppLogger.warning('FCMトークン削除: fcmTokenフィールドが存在しません');
          return; // 既に削除されているか存在しない場合は何もしない
        }

        // トークンを削除（Firebase Functionsが参照する場所）
        await docRef.update({
          'fcmToken': FieldValue.delete(),
        });

        AppLogger.debug('FCMトークン削除: 完了');
      } catch (e) {
        // 特定のエラーをより詳細にハンドリング
        if (e is FirebaseException) {
          if (e.code == 'permission-denied') {
            AppLogger.error('FCMトークン削除エラー: アクセス権限がありません - ${e.message}');
          } else if (e.code == 'unavailable') {
            AppLogger.error('FCMトークン削除エラー: ネットワーク接続の問題 - ${e.message}');
          } else {
            AppLogger.error(
                'FCMトークン削除エラー: Firebase例外 - ${e.code}: ${e.message}');
          }
        } else {
          AppLogger.error('FCMトークン削除エラー: $e');
        }
        // エラーはログに記録するだけで例外は投げない（ログアウト処理を続行させるため）
      }
    } catch (e, stack) {
      AppLogger.error('FCMトークン削除エラー: $e');
      AppLogger.error('スタックトレース: $stack');
      // 例外は投げずにログのみ
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
