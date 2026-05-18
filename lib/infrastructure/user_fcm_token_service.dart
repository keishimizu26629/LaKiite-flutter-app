import 'dart:io';

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

  static const String _legacyTokenField = 'fcmToken';
  static const String _tokenPlatformField = 'fcmTokenPlatform';
  static const String _tokenUpdatedAtField = 'fcmTokenUpdatedAt';
  static const String _tokensField = 'fcmTokens';
  static const String _tokenValueField = 'token';
  static const String _platformField = 'platform';
  static const String _updatedAtField = 'updatedAt';

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

      final platform = _currentPlatformKey();

      // Firebase Functionsが参照する従来フィールドは後方互換のため維持しつつ、
      // iOS/Androidのトークン上書きを避けるためplatform別にも保存する。
      await _firestore.collection('users').doc(user.uid).set({
        _legacyTokenField: token,
        _tokenPlatformField: platform,
        _tokenUpdatedAtField: FieldValue.serverTimestamp(),
        _tokensField: {
          platform: {
            _tokenValueField: token,
            _platformField: platform,
            _updatedAtField: FieldValue.serverTimestamp(),
          },
        },
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

        final platform = _currentPlatformKey();
        final token = await _pushNotificationService.refreshToken();
        final updates = <String, dynamic>{
          '$_tokensField.$platform': FieldValue.delete(),
        };

        final data = docSnapshot.data();
        if (data != null &&
            token != null &&
            data[_legacyTokenField] is String &&
            data[_legacyTokenField] == token) {
          updates[_legacyTokenField] = FieldValue.delete();
          updates[_tokenPlatformField] = FieldValue.delete();
          updates[_tokenUpdatedAtField] = FieldValue.delete();
        }

        await docRef.update(updates);

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
      AppLogger.debug('FCMトークン取得: トークン=${maskNotificationToken(token)}');

      return token;
    } catch (e, stack) {
      AppLogger.error('FCMトークン取得エラー: $e');
      AppLogger.error('スタックトレース: $stack');
      return null;
    }
  }

  /// 特定ユーザーに紐づくFCMトークンを全platform分取得する。
  ///
  /// 旧実装の `fcmToken` も読み込むため、既存データやFunctionsとの後方互換を保てる。
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

    final platformTokens = data[_tokensField];
    if (platformTokens is Map) {
      for (final entry in platformTokens.values) {
        if (entry is String && entry.isNotEmpty) {
          tokens.add(entry);
        } else if (entry is Map) {
          final token = entry[_tokenValueField];
          if (token is String && token.isNotEmpty) {
            tokens.add(token);
          }
        }
      }
    }

    final legacyToken = data[_legacyTokenField];
    if (legacyToken is String && legacyToken.isNotEmpty) {
      tokens.add(legacyToken);
    }

    return tokens.toList(growable: false);
  }

  static String _currentPlatformKey() {
    if (kIsWeb) {
      return 'web';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isMacOS) {
      return 'macos';
    }
    if (Platform.isWindows) {
      return 'windows';
    }
    if (Platform.isLinux) {
      return 'linux';
    }
    return 'unknown';
  }
}
