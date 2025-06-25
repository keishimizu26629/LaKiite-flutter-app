import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../utils/logger.dart';
import '../../firebase_options.dart';

/// Firebaseプッシュ通知の管理を行うサービスクラス
class PushNotificationService {
  final FirebaseMessaging _messaging;

  // シングルトンインスタンス
  static PushNotificationService? _instance;

  // Androidのチャネルを定義

  // シングルトンインスタンスを取得
  static PushNotificationService get instance {
    _instance ??= PushNotificationService._();
    return _instance!;
  }

  // プライベートコンストラクタ
  PushNotificationService._() : _messaging = FirebaseMessaging.instance;

  /// 物理デバイスかどうかを判定
  bool _isPhysicalDevice() {
    if (kIsWeb) return false;

    try {
      // iOS/AndroidでPlatform.environmentを使って判定
      if (Platform.isIOS) {
        // iOSシミュレータの場合、特定の環境変数が設定されている
        return Platform.environment['SIMULATOR_DEVICE_NAME'] == null;
      } else if (Platform.isAndroid) {
        // Androidエミュレータの判定
        final model = Platform.environment['ANDROID_MODEL'] ?? '';
        final product = Platform.environment['ANDROID_PRODUCT'] ?? '';
        return !model.toLowerCase().contains('sdk') &&
            !product.toLowerCase().contains('sdk');
      }
    } catch (e) {
      // エラーの場合は物理デバイスと仮定
      return true;
    }

    return true; // その他のプラットフォームは物理デバイスと仮定
  }

  /// プッシュ通知サービスを初期化
  Future<void> initialize() async {
    try {
      AppLogger.debug('プッシュ通知サービスの初期化を開始');

      // テスト時は通知権限をリクエストしない
      const bool kIsTest =
          bool.fromEnvironment('TEST_MODE', defaultValue: false);
      if (kIsTest) {
        AppLogger.debug('テスト時のため通知権限のリクエストをスキップします');
        return;
      }

      // 通知権限をリクエスト
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogger.debug('通知権限ステータス: ${settings.authorizationStatus}');

      // バックグラウンド処理の設定
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // iOSの場合、APNsトークンに接続
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // APNsトークンを取得（iOS）
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        try {
          final apnsToken = await _messaging.getAPNSToken();
          AppLogger.debug('APNSトークン: $apnsToken');
          if (apnsToken == null) {
            AppLogger.error('APNSトークンがnullです。プッシュ通知が機能しない可能性があります。');
          }
        } catch (e) {
          AppLogger.error('APNSトークン取得エラー: $e');
        }
      }

      // APNsの設定を待機（iOS）
      await Future.delayed(const Duration(seconds: 1));

      // FCMトークンを取得（リトライロジック付き）
      String? token;
      int retryCount = 0;
      const maxRetries = 3;

      while (token == null && retryCount < maxRetries) {
        try {
          token = await _messaging.getToken();
          AppLogger.debug('FCMトークン: $token');
        } catch (e) {
          retryCount++;
          AppLogger.error('FCMトークン取得エラー (試行 $retryCount/$maxRetries): $e');

          if (retryCount < maxRetries) {
            // 指数バックオフでリトライ
            await Future.delayed(Duration(seconds: retryCount * 2));
          }
        }
      }

      if (token == null) {
        AppLogger.error('FCMトークン取得に失敗しました。最大リトライ回数に達しました。');
      }

      // フォアグラウンドメッセージを処理
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.debug('フォアグラウンドメッセージを受信: ${message.messageId}');
        AppLogger.debug('通知タイトル: ${message.notification?.title}');
        AppLogger.debug('通知本文: ${message.notification?.body}');
        AppLogger.debug('データペイロード: ${message.data}');

        _handleMessage(message);
      });

      // アプリが閉じられた状態からの起動時のメッセージを処理
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          AppLogger.debug('初期メッセージを処理: ${message.messageId}');
          _handleMessage(message);
        }
      });

      // バックグラウンド状態からフォアグラウンドに移行時のメッセージを処理
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        AppLogger.debug('バックグラウンドメッセージタップ: ${message.messageId}');
        _handleMessage(message);
      });

      AppLogger.debug('プッシュ通知サービスの初期化が完了');

      // 開発時のトークン表示（デバッグモードのみ）
      await displayTokenForTesting();
    } catch (e, stack) {
      AppLogger.error('プッシュ通知サービスの初期化エラー: $e');
      AppLogger.error('スタックトレース: $stack');
    }
  }

  /// テスト用にFCMトークンを表示（デバッグ専用）
  Future<void> displayTokenForTesting() async {
    try {
      // テスト時は通知権限をリクエストしない
      const bool kIsTest =
          bool.fromEnvironment('TEST_MODE', defaultValue: false);
      if (kIsTest) {
        AppLogger.debug('テスト時のためトークン表示をスキップします');
        return;
      }

      // シミュレータかどうかの判定
      if (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.iOS && !_isPhysicalDevice()) {
        AppLogger.debug('🔧 シミュレータ環境を検出: FCMトークン取得はスキップします');
        print('🔧 シミュレータではプッシュ通知が制限されています。実機でテストしてください。');
        return;
      }

      // FCMの通知権限リクエスト
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false, // iOS 12以上の場合、ダイアログなしで仮承認を行う
        sound: true,
      );

      // トークンの取得
      final token = await messaging.getToken();

      // デバッグ用の表示
      AppLogger.debug('🐯 FCM TOKEN: $token');
      print('🐯 FCM TOKEN: $token'); // コンソールにも表示

      // iOSの場合、APNsトークンも表示
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await messaging.getAPNSToken();
        AppLogger.debug('🍎 APNs TOKEN: $apnsToken');
        print('🍎 APNs TOKEN: $apnsToken');
      }
    } catch (e) {
      AppLogger.error('トークン表示エラー: $e');
      print('❌ トークン取得エラー: $e');
    }
  }

  /// 手動でFCMトークンを取得・表示する（デバッグ用）
  Future<String?> getAndDisplayToken() async {
    try {
      final token = await _messaging.getToken();

      // コンソールとログの両方に表示
      print('🐯 FCM TOKEN: $token');
      AppLogger.debug('手動取得したFCMトークン: $token');

      // iOSの場合、APNsトークンも表示
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _messaging.getAPNSToken();
        print('🍎 APNs TOKEN: $apnsToken');
        AppLogger.debug('APNsトークン: $apnsToken');
      }

      return token;
    } catch (e) {
      print('❌ トークン取得エラー: $e');
      AppLogger.error('手動トークン取得エラー: $e');
      return null;
    }
  }

  /// FCMトークンをリフレッシュ
  Future<String?> refreshToken() async {
    try {
      int retryCount = 0;
      const maxRetries = 3;
      String? token;

      while (token == null && retryCount < maxRetries) {
        try {
          token = await _messaging.getToken();
          AppLogger.debug('FCMトークンをリフレッシュ: $token');
        } catch (e) {
          retryCount++;
          AppLogger.error('FCMトークンのリフレッシュエラー (試行 $retryCount/$maxRetries): $e');

          if (retryCount < maxRetries) {
            await Future.delayed(Duration(seconds: retryCount * 2));
          }
        }
      }

      if (token == null) {
        AppLogger.warning('FCMトークン更新: トークンが取得できませんでした');
      }

      return token;
    } catch (e) {
      AppLogger.error('FCMトークンのリフレッシュエラー: $e');
      return null;
    }
  }

  /// FCMトークンを強制的に更新（削除→再取得）
  /// registration-token-not-registered エラーの解決用
  Future<String?> forceUpdateFCMToken() async {
    try {
      AppLogger.debug('FCMトークンの強制更新を開始');

      // 既存トークンを削除
      await _messaging.deleteToken();
      AppLogger.debug('既存FCMトークンを削除しました');

      // 短時間待機してからトークンを再取得
      await Future.delayed(const Duration(seconds: 2));

      // 新しいトークンを取得（リトライロジック付き）
      String? newToken;
      int retryCount = 0;
      const maxRetries = 5;

      while (newToken == null && retryCount < maxRetries) {
        try {
          newToken = await _messaging.getToken();
          if (newToken != null) {
            AppLogger.debug('新しいFCMトークンを取得: $newToken');
          }
        } catch (e) {
          retryCount++;
          AppLogger.error('FCMトークン強制更新エラー (試行 $retryCount/$maxRetries): $e');

          if (retryCount < maxRetries) {
            // 指数バックオフでリトライ
            await Future.delayed(Duration(seconds: retryCount * 2));
          }
        }
      }

      if (newToken == null) {
        AppLogger.error('FCMトークンの強制更新に失敗しました。最大リトライ回数に達しました。');
      } else {
        AppLogger.debug('FCMトークンの強制更新が完了しました');
        // TODO: 新しいトークンをFirestoreに保存する処理を呼び出し
        // await _userRepository.updateFCMToken(newToken);
      }

      return newToken;
    } catch (e) {
      AppLogger.error('FCMトークン強制更新エラー: $e');
      return null;
    }
  }

  /// 特定のトピックを購読
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      AppLogger.debug('トピックを購読: $topic');
    } catch (e) {
      AppLogger.error('トピック購読エラー: $e');
    }
  }

  /// トピックの購読を解除
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      AppLogger.debug('トピック購読を解除: $topic');
    } catch (e) {
      AppLogger.error('トピック購読解除エラー: $e');
    }
  }

  /// 受信したメッセージを処理
  void _handleMessage(RemoteMessage message) {
    try {
      final data = message.data;
      final notificationType = data['type'];

      AppLogger.debug('メッセージの処理: タイプ=$notificationType');

      // 通知タイプに基づいた処理
      switch (notificationType) {
        case 'friend_request':
          _handleFriendRequest(data);
          break;
        case 'group_invitation':
          _handleGroupInvitation(data);
          break;
        case 'reaction':
          _handleReaction(data);
          break;
        case 'comment':
          _handleComment(data);
          break;
        default:
          AppLogger.debug('未知の通知タイプ: $notificationType');
      }
    } catch (e) {
      AppLogger.error('メッセージ処理エラー: $e');
    }
  }

  /// 友人申請メッセージを処理
  void _handleFriendRequest(Map<String, dynamic> data) {
    // TODO: 友人申請の通知処理を実装
    AppLogger.debug('友人申請メッセージを処理: $data');
  }

  /// グループ招待メッセージを処理
  void _handleGroupInvitation(Map<String, dynamic> data) {
    // TODO: グループ招待の通知処理を実装
    AppLogger.debug('グループ招待メッセージを処理: $data');
  }

  /// リアクションメッセージを処理
  void _handleReaction(Map<String, dynamic> data) {
    // TODO: リアクションの通知処理を実装
    AppLogger.debug('リアクションメッセージを処理: $data');
  }

  /// コメントメッセージを処理
  void _handleComment(Map<String, dynamic> data) {
    // TODO: コメントの通知処理を実装
    AppLogger.debug('コメントメッセージを処理: $data');
  }
}

/// バックグラウンドメッセージハンドラー
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebaseの初期化を確認
  if (!Firebase.apps.isNotEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  AppLogger.debug('バックグラウンドメッセージを処理: ${message.messageId}');
  AppLogger.debug('データペイロード: ${message.data}');
}
