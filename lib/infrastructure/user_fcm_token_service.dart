import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../infrastructure/firebase/push_notification_service.dart';
import '../utils/logger.dart';
import '../utils/notification_token_log_formatter.dart';

/// ユーザーのFCMトークンを管理するサービスクラス
class UserFcmTokenService {
  UserFcmTokenService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _pushNotificationService = PushNotificationService.instance;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PushNotificationService _pushNotificationService;

  static const String _tokensField = 'fcmTokens';

  /// 現在のユーザーのFCMトークンを更新する
  Future<bool> updateCurrentUserFcmToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        AppLogger.warning('FCMトークン更新: ユーザーがログインしていません');
        return false;
      }

      final token = await _pushNotificationService.refreshToken();
      if (token == null) {
        AppLogger.warning('FCMトークン更新: トークンが取得できませんでした');
        return false;
      }

      AppLogger.debug(
          'FCMトークン更新: ユーザーID=${user.uid}, トークン=${maskNotificationToken(token)}');

      // ZENと同じく、複数端末のトークンを配列で保持する。
      // 単一fcmTokenフィールドは使わず、iOS/Androidや複数端末の上書きを避ける。
      await _firestore.collection('users').doc(user.uid).set({
        _tokensField: FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      AppLogger.debug('FCMトークン更新: 完了');
      return true;
    } catch (e, stack) {
      AppLogger.error('FCMトークン更新エラー: $e');
      AppLogger.error('スタックトレース: $stack');
      return false;
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

        final token = await _pushNotificationService.refreshToken();
        if (token == null) {
          AppLogger.warning('FCMトークン削除: 現在端末のトークンが取得できませんでした');
          return;
        }

        await docRef.update({
          _tokensField: FieldValue.arrayRemove([token]),
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

      final tokens = extractFcmTokens(doc.data());
      final token = tokens.isEmpty ? null : tokens.first;
      AppLogger.debug('FCMトークン取得: トークン=${maskNotificationToken(token)}');

      return token;
    } catch (e, stack) {
      AppLogger.error('FCMトークン取得エラー: $e');
      AppLogger.error('スタックトレース: $stack');
      return null;
    }
  }

  /// 特定ユーザーに紐づくFCMトークンを全端末分取得する。
  Future<List<String>> getUserFcmTokens(String userId) async {
    try {
      AppLogger.debug('FCMトークン一覧取得: ユーザーID=$userId');

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        AppLogger.warning('FCMトークン一覧取得: ユーザーが存在しません - $userId');
        return const [];
      }

      final tokens = extractFcmTokens(doc.data());
      AppLogger.debug(
          'FCMトークン一覧取得: ${tokens.length}件 (${tokens.map(maskNotificationToken).join(', ')})');
      return tokens;
    } catch (e, stack) {
      AppLogger.error('FCMトークン一覧取得エラー: $e');
      AppLogger.error('スタックトレース: $stack');
      return const [];
    }
  }

  @visibleForTesting
  static List<String> extractFcmTokens(Map<String, dynamic>? data) {
    if (data == null) {
      return const [];
    }

    final tokens = <String>{};

    final rawTokens = data[_tokensField];
    if (rawTokens is Iterable) {
      for (final token in rawTokens) {
        if (token is String && token.isNotEmpty) {
          tokens.add(token);
        }
      }
    }

    return tokens.toList(growable: false);
  }
}
