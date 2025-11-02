import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../user_fcm_token_service.dart';
import '../../utils/logger.dart';

/// Firebaseプッシュ通知の管理を行うサービスクラス
class PushNotificationService {
  PushNotificationService._() : _messaging = FirebaseMessaging.instance;
  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static PushNotificationService? _instance;

  static PushNotificationService get instance {
    _instance ??= PushNotificationService._();
    return _instance!;
  }

  Future<void> initialize() async {
    try {
      AppLogger.debug('プッシュ通知サービスの初期化を開始');

      if (_shouldSkipInitialization()) {
        AppLogger.debug('テストモードのため初期化をスキップします');
        return;
      }

      if (Platform.isAndroid) {
        await _setupAndroidEnvironment();
      }

      final settings = await _requestNotificationPermission();
      _logPermissionDetails(settings);

      _configureBackgroundHandlers();
      await _configureForegroundNotifications();
      await _prepareIosApns();

      final token = await _obtainFcmTokenWithRetry();
      await _persistFcmToken(token);

      _setupMessageListeners();

      AppLogger.info('🎉 プッシュ通知サービスの初期化が完了しました！');
      await displayTokenForTesting();
    } catch (e, stack) {
      AppLogger.error('プッシュ通知サービスの初期化エラー: $e');
      AppLogger.error('スタックトレース: $stack');
    }
  }

  /// アプリアイコンのバッジカウントをクリアする
  Future<void> clearBadgeCount() async {
    try {
      AppLogger.debug('アプリアイコンのバッジカウントをクリアします');

      if (Platform.isIOS) {
        // iOSの場合、ネイティブ側（AppDelegate.swift）でバッジクリアを処理
        // ここではログ出力のみ行う
        AppLogger.info('✅ iOSアプリアイコンのバッジカウントクリア（ネイティブ側で処理）');
      } else if (Platform.isAndroid) {
        // Androidの場合、通知チャネルを通じてバッジをクリア
        final androidImplementation = _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          // Androidでは通知をキャンセルすることでバッジをクリア
          await androidImplementation.cancelAll();
          AppLogger.info('✅ Android通知バッジをクリアしました');
        }
      }
    } catch (e, stack) {
      AppLogger.error('バッジカウントクリアエラー: $e');
      AppLogger.error('スタックトレース: $stack');
    }
  }

  Future<void> displayTokenForTesting() async {
    try {
      if (_shouldSkipInitialization()) {
        return;
      }

      if (kIsWeb ||
          (defaultTargetPlatform == TargetPlatform.iOS &&
              !_isPhysicalDevice())) {
        AppLogger.debug('🔧 シミュレータ環境のためトークン表示をスキップします');
        return;
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final token = await messaging.getToken();
      AppLogger.info('🐯 FCM TOKEN: $token');

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await messaging.getAPNSToken();
        AppLogger.info('🍎 APNs TOKEN: $apnsToken');
      }
    } catch (e) {
      AppLogger.error('❌ トークン取得エラー: $e');
    }
  }

  Future<String?> getAndDisplayToken() async {
    try {
      final token = await _messaging.getToken();
      AppLogger.info('🐯 手動取得したFCMトークン: $token');
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

  Future<String?> forceUpdateFCMToken() async {
    try {
      AppLogger.debug('FCMトークンの強制更新を開始');
      await _messaging.deleteToken();
      AppLogger.debug('既存FCMトークンを削除しました');
      await Future.delayed(const Duration(seconds: 2));

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
            await Future.delayed(Duration(seconds: retryCount * 2));
          }
        }
      }

      if (newToken == null) {
        AppLogger.error('FCMトークンの強制更新に失敗しました。最大リトライ回数に達しました。');
      } else {
        AppLogger.debug('FCMトークンの強制更新が完了しました');
        try {
          final fcmTokenService = UserFcmTokenService();
          await fcmTokenService.updateCurrentUserFcmToken();
          AppLogger.info('✅ 強制更新されたFCMトークンのFirestore保存完了');
        } catch (e) {
          AppLogger.error('❌ 強制更新されたFCMトークンのFirestore保存エラー: $e');
        }
      }

      return newToken;
    } catch (e) {
      AppLogger.error('FCMトークン強制更新エラー: $e');
      return null;
    }
  }

  bool _shouldSkipInitialization() {
    const bool kIsTest = bool.fromEnvironment('TEST_MODE', defaultValue: false);
    return kIsTest;
  }

  Future<void> _setupAndroidEnvironment() async {
    AppLogger.info('🤖 Android環境での初期化を開始...');
    await _initializeLocalNotifications();
    await _createNotificationChannels();
    _logAndroidVersionInfo();
  }

  void _logAndroidVersionInfo() {
    try {
      final androidVersion = Platform.version;
      AppLogger.info('🤖 Android バージョン情報: $androidVersion');

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

  Future<NotificationSettings> _requestNotificationPermission() async {
    AppLogger.info('🔔 通知権限をリクエスト開始...');
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  void _logPermissionDetails(NotificationSettings settings) {
    AppLogger.info('🔔 通知権限ステータス: ${settings.authorizationStatus}');
    AppLogger.info(
        '🔔 通知設定詳細: alert=${settings.alert}, badge=${settings.badge}, sound=${settings.sound}');

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
  }

  void _configureBackgroundHandlers() {
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );
  }

  Future<void> _configureForegroundNotifications() async {
    AppLogger.info('📱 フォアグラウンド通知設定を開始...');
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    AppLogger.info('✅ フォアグラウンド通知設定完了: alert=true, badge=true, sound=true');
  }

  Future<void> _prepareIosApns() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    try {
      final apnsToken = await _messaging.getAPNSToken();
      AppLogger.debug('APNSトークン: $apnsToken');
      if (apnsToken == null) {
        AppLogger.error('APNSトークンがnullです。プッシュ通知が機能しない可能性があります。');
      }
    } catch (e) {
      AppLogger.error('APNSトークン取得エラー: $e');
    }

    await Future.delayed(const Duration(seconds: 1));
  }

  Future<String?> _obtainFcmTokenWithRetry() async {
    String? token;
    int retryCount = 0;
    const maxRetries = 3;

    if (Platform.isAndroid) {
      AppLogger.info('🤖 Android FCMトークン取得の事前チェック...');
      AppLogger.info('🤖 Google Play開発者サービスの状態確認...');
    }

    while (token == null && retryCount < maxRetries) {
      try {
        AppLogger.info('🐯 FCMトークン取得試行 ${retryCount + 1}/$maxRetries...');

        if (Platform.isAndroid) {
          AppLogger.info(
              '🤖 Android: FirebaseMessaging.instance.getToken() 呼び出し...');
        }

        token = await _messaging.getToken();

        if (token != null) {
          AppLogger.info('🐯 FCMトークン取得成功: $token');
          AppLogger.info('🐯 トークン長: ${token.length}文字');

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
          final waitSeconds = retryCount * 2;
          AppLogger.info('⏳ $waitSeconds秒後にリトライします...');
          await Future.delayed(Duration(seconds: waitSeconds));
        }
      }
    }

    return token;
  }

  Future<void> _persistFcmToken(String? token) async {
    if (token == null) {
      AppLogger.error('❌ FCMトークン取得に失敗しました。最大リトライ回数に達しました。');
      AppLogger.error('❌ プッシュ通知が正常に動作しない可能性があります。');
      AppLogger.info('💡 トラブルシューティング:');
      AppLogger.info('   - ネットワーク接続を確認してください');
      AppLogger.info('   - Firebase設定を確認してください');
      AppLogger.info('   - 実機でテストしてください（シミュレータでは制限があります）');
      return;
    }

    AppLogger.info('✅ FCMトークン取得完了！プッシュ通知の準備ができました。');

    try {
      AppLogger.debug('🔄 FCMトークンをFirestoreに保存中...');
      final fcmTokenService = UserFcmTokenService();
      await fcmTokenService.updateCurrentUserFcmToken();
      AppLogger.info('✅ FCMトークンのFirestore保存完了');
    } catch (e) {
      AppLogger.error('❌ FCMトークンのFirestore保存エラー: $e');
    }
  }

  void _setupMessageListeners() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info('📱 フォアグラウンドで通知を受信: ${message.messageId}');
      AppLogger.info('📱 通知タイトル: ${message.notification?.title}');
      AppLogger.info('📱 通知本文: ${message.notification?.body}');
      AppLogger.info('📱 データペイロード: ${message.data}');
      AppLogger.info('📱 送信時刻: ${message.sentTime}');
      AppLogger.info('📱 TTL: ${message.ttl}');

      if (Platform.isAndroid) {
        _showForegroundNotification(message);
      }

      _handleMessage(message);
    });

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

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AppLogger.info('👆 バックグラウンド通知をタップしてアプリ起動: ${message.messageId}');
      AppLogger.info('👆 通知タイトル: ${message.notification?.title}');
      AppLogger.info('👆 通知本文: ${message.notification?.body}');
      AppLogger.info('👆 データペイロード: ${message.data}');
      _handleMessage(message);
    });
  }

  bool _isPhysicalDevice() {
    if (kIsWeb) return false;

    try {
      if (Platform.isIOS) {
        return Platform.environment['SIMULATOR_DEVICE_NAME'] == null;
      } else if (Platform.isAndroid) {
        final model = Platform.environment['ANDROID_MODEL'] ?? '';
        final product = Platform.environment['ANDROID_PRODUCT'] ?? '';
        return !model.toLowerCase().contains('sdk') &&
            !product.toLowerCase().contains('sdk');
      }
    } catch (_) {
      return true;
    }

    return true;
  }

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

  Future<void> _createNotificationChannels() async {
    try {
      AppLogger.info('📢 Android通知チャネルの作成を開始...');

      const AndroidNotificationChannel highImportanceChannel =
          AndroidNotificationChannel(
        'high_importance_channel',
        'フォアグラウンド通知',
        description: 'アプリ使用中に表示される重要な通知',
        importance: Importance.max,
        showBadge: true,
        enableVibration: true,
        enableLights: true,
      );

      const AndroidNotificationChannel generalChannel =
          AndroidNotificationChannel(
        'general_notifications',
        '一般通知',
        description: '一般的な通知を表示します',
        importance: Importance.defaultImportance,
      );

      const AndroidNotificationChannel importantChannel =
          AndroidNotificationChannel(
        'important_notifications',
        '重要な通知',
        description: '重要な通知を表示します',
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      const AndroidNotificationChannel friendRequestChannel =
          AndroidNotificationChannel(
        'friend_request_notifications',
        '友達申請',
        description: '友達申請に関する通知を表示します',
        importance: Importance.high,
      );

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
      } else {
        AppLogger.error('❌ AndroidFlutterLocalNotificationsPlugin が取得できませんでした');
      }
    } catch (e) {
      AppLogger.error('❌ 通知チャネル作成エラー: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    try {
      final data = message.data;
      final notificationType = data['type'];

      AppLogger.info('🔄 通知メッセージの処理を開始');
      AppLogger.info('🔄 メッセージID: ${message.messageId}');
      AppLogger.info('🔄 通知タイプ: $notificationType');
      AppLogger.info('🔄 データ: $data');

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

  void _handleFriendRequest(Map<String, dynamic> data) {
    AppLogger.info('👥 友人申請メッセージを処理中');
    AppLogger.info('👥 送信元ユーザーID: ${data['fromUserId']}');
    AppLogger.info('👥 送信元ユーザー名: ${data['fromUserName']}');
    AppLogger.info('👥 データ詳細: $data');
  }

  void _handleGroupInvitation(Map<String, dynamic> data) {
    AppLogger.info('👫 グループ招待メッセージを処理中');
    AppLogger.info('👫 招待者ユーザーID: ${data['fromUserId']}');
    AppLogger.info('👫 グループID: ${data['groupId']}');
    AppLogger.info('👫 グループ名: ${data['groupName']}');
    AppLogger.info('👫 データ詳細: $data');
  }

  void _handleReaction(Map<String, dynamic> data) {
    AppLogger.info('👍 リアクションメッセージを処理中');
    AppLogger.info('👍 送信元ユーザーID: ${data['fromUserId']}');
    AppLogger.info('👍 スケジュールID: ${data['scheduleId']}');
    AppLogger.info('👍 リアクションタイプ: ${data['reactionType']}');
    AppLogger.info('👍 データ詳細: $data');
  }

  void _handleComment(Map<String, dynamic> data) {
    AppLogger.info('💬 コメントメッセージを処理中');
    AppLogger.info('💬 送信元ユーザーID: ${data['fromUserId']}');
    AppLogger.info('💬 スケジュールID: ${data['scheduleId']}');
    AppLogger.info('💬 コメント内容: ${data['commentText']}');
    AppLogger.info('💬 データ詳細: $data');
  }

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
              'high_importance_channel',
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
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

  if (Platform.isAndroid) {
    AppLogger.info('🤖 Android バックグラウンド処理詳細:');
    AppLogger.info('🤖 - メッセージID: ${message.messageId}');
    AppLogger.info('🤖 - 通知オブジェクト存在: ${message.notification != null}');
    AppLogger.info('🤖 - データオブジェクト存在: ${message.data.isNotEmpty}');
    AppLogger.info('🤖 - TTL: ${message.ttl}');

    if (message.notification != null) {
      AppLogger.info('🤖 - Android通知設定: ${message.notification!.android}');
    }

    if (message.notification == null && message.data.isNotEmpty) {
      AppLogger.info('🤖 data-onlyメッセージを検出: カスタム処理が必要');
    } else if (message.notification != null) {
      AppLogger.info('🤖 notificationメッセージを検出: システム通知が自動表示されます');
    }
  }
}
