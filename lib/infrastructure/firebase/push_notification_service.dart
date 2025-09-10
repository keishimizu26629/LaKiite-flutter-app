import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import '../../utils/logger.dart';
import '../../firebase_options.dart';
import '../user_fcm_token_service.dart';

/// Firebaseプッシュ通知の管理を行うサービスクラス
class PushNotificationService {
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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

      // Androidの通知チャネルを設定
      if (Platform.isAndroid) {
        AppLogger.info('🤖 Android環境での初期化を開始...');
        await _initializeLocalNotifications();
        await _createNotificationChannels();

        // Android環境の詳細情報をログ出力
        try {
          final androidVersion = Platform.version;
          AppLogger.info('🤖 Android バージョン情報: $androidVersion');

          // Android 13+ (API 33+) の判定
          if (androidVersion.contains('API')) {
            final apiMatch = RegExp(r'API (\d+)').firstMatch(androidVersion);
            if (apiMatch != null) {
              final apiLevel = int.tryParse(apiMatch.group(1)!);
              if (apiLevel != null && apiLevel >= 33) {
                AppLogger.info(
                    '🔔 Android 13+ (API $apiLevel) を検出: POST_NOTIFICATIONS権限が必要です');
              } else {
                AppLogger.info(
                    '🔔 Android 12以下 (API $apiLevel) を検出: POST_NOTIFICATIONS権限は不要です');
              }
            }
          }
        } catch (e) {
          AppLogger.warning('Android バージョン情報の解析エラー: $e');
        }
      }

      // 通知権限をリクエスト
      AppLogger.info('🔔 通知権限をリクエスト開始...');
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogger.info('🔔 通知権限ステータス: ${settings.authorizationStatus}');
      AppLogger.info(
          '🔔 通知設定詳細: alert=${settings.alert}, badge=${settings.badge}, sound=${settings.sound}');

      // 権限ステータスに応じた詳細ログ
      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          AppLogger.info('✅ プッシュ通知が許可されました');
          break;
        case AuthorizationStatus.denied:
          AppLogger.warning('❌ プッシュ通知が拒否されました');
          break;
        case AuthorizationStatus.notDetermined:
          AppLogger.info('❓ プッシュ通知の許可状態が未決定です');
          break;
        case AuthorizationStatus.provisional:
          AppLogger.info('⚡ プッシュ通知が仮許可されました（iOS 12以上）');
          break;
      }

      // バックグラウンド処理の設定
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // フォアグラウンド通知の設定（iOS・Android共通）
      AppLogger.info('📱 フォアグラウンド通知設定を開始...');
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true, // 通知バナーを表示
        badge: true, // バッジ数を更新
        sound: true, // 通知音を再生
      );
      AppLogger.info('✅ フォアグラウンド通知設定完了: alert=true, badge=true, sound=true');

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

      // Android特有のトークン取得前チェック
      if (Platform.isAndroid) {
        AppLogger.info('🤖 Android FCMトークン取得の事前チェック...');
        AppLogger.info('🤖 Google Play開発者サービスの状態確認...');
      }

      while (token == null && retryCount < maxRetries) {
        try {
          AppLogger.info('🐯 FCMトークン取得試行 ${retryCount + 1}/$maxRetries...');

          // Androidの場合、より詳細なログ
          if (Platform.isAndroid) {
            AppLogger.info(
                '🤖 Android: FirebaseMessaging.instance.getToken() 呼び出し...');
          }

          token = await _messaging.getToken();

          if (token != null) {
            AppLogger.info('🐯 FCMトークン取得成功: $token');
            AppLogger.info('🐯 トークン長: ${token.length}文字');

            // Androidの場合、トークンの詳細検証
            if (Platform.isAndroid) {
              AppLogger.info('🤖 Android FCMトークン詳細:');
              AppLogger.info('🤖 - トークンの先頭10文字: ${token.substring(0, 10)}...');
              AppLogger.info('🤖 - トークンにコロン含む: ${token.contains(':')}');
              AppLogger.info(
                  '🤖 - トークン形式確認: ${token.startsWith('f') || token.startsWith('c') || token.startsWith('d') ? '正常' : '異常'}');
            }
          } else {
            AppLogger.error('❌ FCMトークンがnullで返されました');
            if (Platform.isAndroid) {
              AppLogger.error(
                  '🤖 Android: google-services.jsonとpackageNameの一致を確認してください');
              AppLogger.error('🤖 Android: Google Play開発者サービスが利用可能か確認してください');
            }
          }
        } catch (e) {
          retryCount++;
          AppLogger.error('❌ FCMトークン取得エラー (試行 $retryCount/$maxRetries): $e');

          // Androidの場合、エラーの詳細分析
          if (Platform.isAndroid) {
            AppLogger.error('🤖 Android FCMエラー詳細:');
            AppLogger.error('🤖 エラータイプ: ${e.runtimeType}');
            AppLogger.error('🤖 エラーメッセージ: $e');

            if (e.toString().contains('SERVICE_NOT_AVAILABLE')) {
              AppLogger.error('🤖 Google Play開発者サービスが利用できません');
            } else if (e.toString().contains('NETWORK_ERROR')) {
              AppLogger.error('🤖 ネットワークエラーです。インターネット接続を確認してください');
            } else if (e.toString().contains('INVALID_SENDER')) {
              AppLogger.error('🤖 google-services.jsonの設定に問題があります');
            }
          }

          if (retryCount < maxRetries) {
            // 指数バックオフでリトライ
            final waitSeconds = retryCount * 2;
            AppLogger.info('⏳ ${waitSeconds}秒後にリトライします...');
            await Future.delayed(Duration(seconds: waitSeconds));
          }
        }
      }

      if (token == null) {
        AppLogger.error('❌ FCMトークン取得に失敗しました。最大リトライ回数に達しました。');
        AppLogger.error('❌ プッシュ通知が正常に動作しない可能性があります。');
        AppLogger.info('💡 トラブルシューティング:');
        AppLogger.info('   - ネットワーク接続を確認してください');
        AppLogger.info('   - Firebase設定を確認してください');
        AppLogger.info('   - 実機でテストしてください（シミュレータでは制限があります）');
      } else {
        AppLogger.info('✅ FCMトークン取得完了！プッシュ通知の準備ができました。');

        // FCMトークンをFirestoreに保存
        try {
          AppLogger.debug('🔄 FCMトークンをFirestoreに保存中...');
          final fcmTokenService = UserFcmTokenService();
          await fcmTokenService.updateCurrentUserFcmToken();
          AppLogger.info('✅ FCMトークンのFirestore保存完了');
        } catch (e) {
          AppLogger.error('❌ FCMトークンのFirestore保存エラー: $e');
          // エラーが発生してもプッシュ通知サービスの初期化は継続
        }
      }

      // フォアグラウンドメッセージを処理
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        AppLogger.info('📱 フォアグラウンドで通知を受信: ${message.messageId}');
        AppLogger.info('📱 通知タイトル: ${message.notification?.title}');
        AppLogger.info('📱 通知本文: ${message.notification?.body}');
        AppLogger.info('📱 データペイロード: ${message.data}');
        AppLogger.info('📱 送信時刻: ${message.sentTime}');
        AppLogger.info('📱 TTL: ${message.ttl}');

        // Androidでフォアグラウンド通知を表示
        if (Platform.isAndroid) {
          _showForegroundNotification(message);
        }

        _handleMessage(message);
      });

      // アプリが閉じられた状態からの起動時のメッセージを処理
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          AppLogger.info('🚀 アプリ起動時の通知を処理: ${message.messageId}');
          AppLogger.info('🚀 通知タイトル: ${message.notification?.title}');
          AppLogger.info('🚀 通知本文: ${message.notification?.body}');
          AppLogger.info('🚀 データペイロード: ${message.data}');
          _handleMessage(message);
        } else {
          AppLogger.debug('🚀 アプリ起動時に処理すべき通知はありません');
        }
      });

      // バックグラウンド状態からフォアグラウンドに移行時のメッセージを処理
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        AppLogger.info('👆 バックグラウンド通知をタップしてアプリ起動: ${message.messageId}');
        AppLogger.info('👆 通知タイトル: ${message.notification?.title}');
        AppLogger.info('👆 通知本文: ${message.notification?.body}');
        AppLogger.info('👆 データペイロード: ${message.data}');
        _handleMessage(message);
      });

      AppLogger.info('🎉 プッシュ通知サービスの初期化が完了しました！');

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
        AppLogger.info('🔧 シミュレータではプッシュ通知が制限されています。実機でテストしてください。');
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
      AppLogger.info('🐯 FCM TOKEN: $token');

      // iOSの場合、APNsトークンも表示
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await messaging.getAPNSToken();
        AppLogger.info('🍎 APNs TOKEN: $apnsToken');
      }
    } catch (e) {
      AppLogger.error('❌ トークン取得エラー: $e');
    }
  }

  /// 手動でFCMトークンを取得・表示する（デバッグ用）
  Future<String?> getAndDisplayToken() async {
    try {
      final token = await _messaging.getToken();

      // ログに表示
      AppLogger.info('🐯 手動取得したFCMトークン: $token');

      // iOSの場合、APNsトークンも表示
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        AppLogger.info('🍎 APNsトークン: $apnsToken');
      }

      return token;
    } catch (e) {
      AppLogger.error('❌ 手動トークン取得エラー: $e');
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

        // 新しいトークンをFirestoreに保存
        try {
          AppLogger.debug('🔄 強制更新されたFCMトークンをFirestoreに保存中...');
          final fcmTokenService = UserFcmTokenService();
          await fcmTokenService.updateCurrentUserFcmToken();
          AppLogger.info('✅ 強制更新されたFCMトークンのFirestore保存完了');
        } catch (e) {
          AppLogger.error('❌ 強制更新されたFCMトークンのFirestore保存エラー: $e');
          // エラーが発生してもトークン更新処理は継続
        }
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

      AppLogger.info('🔄 通知メッセージの処理を開始');
      AppLogger.info('🔄 メッセージID: ${message.messageId}');
      AppLogger.info('🔄 通知タイプ: $notificationType');
      AppLogger.info('🔄 データ: $data');

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
          AppLogger.warning('⚠️ 未知の通知タイプ: $notificationType');
          AppLogger.info(
              '💡 サポートされている通知タイプ: friend_request, group_invitation, reaction, comment');
      }
    } catch (e) {
      AppLogger.error('メッセージ処理エラー: $e');
    }
  }

  /// 友人申請メッセージを処理
  void _handleFriendRequest(Map<String, dynamic> data) {
    // 友人申請の通知処理は今後実装予定
    AppLogger.info('👥 友人申請メッセージを処理中');
    AppLogger.info('👥 送信元ユーザーID: ${data['fromUserId']}');
    AppLogger.info('👥 送信元ユーザー名: ${data['fromUserName']}');
    AppLogger.info('👥 データ詳細: $data');
  }

  /// グループ招待メッセージを処理
  void _handleGroupInvitation(Map<String, dynamic> data) {
    // グループ招待の通知処理は今後実装予定
    AppLogger.info('👫 グループ招待メッセージを処理中');
    AppLogger.info('👫 招待者ユーザーID: ${data['fromUserId']}');
    AppLogger.info('👫 グループID: ${data['groupId']}');
    AppLogger.info('👫 グループ名: ${data['groupName']}');
    AppLogger.info('👫 データ詳細: $data');
  }

  /// リアクションメッセージを処理
  void _handleReaction(Map<String, dynamic> data) {
    // リアクションの通知処理は今後実装予定
    AppLogger.info('👍 リアクションメッセージを処理中');
    AppLogger.info('👍 送信元ユーザーID: ${data['fromUserId']}');
    AppLogger.info('👍 スケジュールID: ${data['scheduleId']}');
    AppLogger.info('👍 リアクションタイプ: ${data['reactionType']}');
    AppLogger.info('👍 データ詳細: $data');
  }

  /// コメントメッセージを処理
  void _handleComment(Map<String, dynamic> data) {
    // コメントの通知処理は今後実装予定
    AppLogger.info('💬 コメントメッセージを処理中');
    AppLogger.info('💬 送信元ユーザーID: ${data['fromUserId']}');
    AppLogger.info('💬 スケジュールID: ${data['scheduleId']}');
    AppLogger.info('💬 コメント内容: ${data['commentText']}');
    AppLogger.info('💬 データ詳細: $data');
  }

  /// Androidでフォアグラウンド通知を表示
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null) {
        AppLogger.info('🔔 Androidフォアグラウンド通知を表示: ${notification.title}');

        await _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel', // 高重要度チャネルを使用
              'フォアグラウンド通知',
              channelDescription: 'アプリ使用中に表示される重要な通知',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
              icon: android?.smallIcon,
              styleInformation: BigTextStyleInformation(
                notification.body ?? '',
                htmlFormatBigText: true,
                contentTitle: notification.title,
                htmlFormatContentTitle: true,
              ),
            ),
          ),
          payload: message.data.isNotEmpty ? message.data.toString() : null,
        );

        AppLogger.info('✅ フォアグラウンド通知表示完了');
      } else {
        AppLogger.warning('⚠️ 通知データが空のため、フォアグラウンド通知をスキップします');
      }
    } catch (e) {
      AppLogger.error('❌ フォアグラウンド通知表示エラー: $e');
    }
  }

  /// ローカル通知を初期化
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    AppLogger.debug('ローカル通知を初期化しました');
  }

  /// Android通知チャネルを作成
  Future<void> _createNotificationChannels() async {
    try {
      AppLogger.info('📢 Android通知チャネルの作成を開始...');

      // 高重要度通知チャネル（フォアグラウンド通知用）
      const AndroidNotificationChannel highImportanceChannel =
          AndroidNotificationChannel(
        'high_importance_channel',
        'フォアグラウンド通知',
        description: 'アプリ使用中に表示される重要な通知',
        importance: Importance.max, // フォアグラウンド通知に必要
        showBadge: true,
        enableVibration: true,
        enableLights: true,
      );

      // 一般的な通知チャネル
      const AndroidNotificationChannel generalChannel =
          AndroidNotificationChannel(
        'general_notifications',
        '一般通知',
        description: '一般的な通知を表示します',
        importance: Importance.defaultImportance,
      );

      // 重要な通知チャネル
      const AndroidNotificationChannel importantChannel =
          AndroidNotificationChannel(
        'important_notifications',
        '重要な通知',
        description: '重要な通知を表示します',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      // 友達申請専用チャネル
      const AndroidNotificationChannel friendRequestChannel =
          AndroidNotificationChannel(
        'friend_request_notifications',
        '友達申請',
        description: '友達申請に関する通知を表示します',
        importance: Importance.high,
      );

      // リアクション通知チャネル
      const AndroidNotificationChannel reactionChannel =
          AndroidNotificationChannel(
        'reaction_notifications',
        'リアクション通知',
        description: 'リアクションに関する通知を表示します',
        importance: Importance.defaultImportance,
      );

      final plugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (plugin != null) {
        await plugin.createNotificationChannel(highImportanceChannel);
        await plugin.createNotificationChannel(generalChannel);
        await plugin.createNotificationChannel(importantChannel);
        await plugin.createNotificationChannel(friendRequestChannel);
        await plugin.createNotificationChannel(reactionChannel);
        AppLogger.info('✅ Android通知チャネル作成完了 (5チャネル)');
        AppLogger.info('   - 高重要度チャネル: high_importance_channel (フォアグラウンド用)');
        AppLogger.info('   - 一般通知: general_notifications');
        AppLogger.info('   - 重要通知: important_notifications');
        AppLogger.info('   - 友達申請: friend_request_notifications');
        AppLogger.info('   - リアクション: reaction_notifications');
      } else {
        AppLogger.error('❌ AndroidFlutterLocalNotificationsPlugin が取得できませんでした');
      }
    } catch (e) {
      AppLogger.error('❌ 通知チャネル作成エラー: $e');
    }
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

  AppLogger.info('🌙 バックグラウンドで通知を受信: ${message.messageId}');
  AppLogger.info('🌙 通知タイトル: ${message.notification?.title}');
  AppLogger.info('🌙 通知本文: ${message.notification?.body}');
  AppLogger.info('🌙 データペイロード: ${message.data}');
  AppLogger.info('🌙 送信時刻: ${message.sentTime}');
  AppLogger.info('🌙 通知タイプ: ${message.data['type']}');

  // Android特有のバックグラウンド処理ログ
  if (Platform.isAndroid) {
    AppLogger.info('🤖 Android バックグラウンド処理詳細:');
    AppLogger.info('🤖 - メッセージID: ${message.messageId}');
    AppLogger.info('🤖 - 通知オブジェクト存在: ${message.notification != null}');
    AppLogger.info('🤖 - データオブジェクト存在: ${message.data.isNotEmpty}');
    AppLogger.info('🤖 - TTL: ${message.ttl}');

    if (message.notification != null) {
      AppLogger.info('🤖 - Android通知設定: ${message.notification!.android}');
    }

    // data-onlyメッセージかnotificationメッセージかの判定
    if (message.notification == null && message.data.isNotEmpty) {
      AppLogger.info('🤖 data-onlyメッセージを検出: カスタム処理が必要');
    } else if (message.notification != null) {
      AppLogger.info('🤖 notificationメッセージを検出: システム通知が自動表示されます');
    }
  }
}
