import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../utils/logger.dart';

/// デバッグ用：プッシュ通知トークン表示ページ
class DebugNotificationPage extends StatefulWidget {
  const DebugNotificationPage({super.key});

  @override
  State<DebugNotificationPage> createState() => _DebugNotificationPageState();
}

class _DebugNotificationPageState extends State<DebugNotificationPage> {
  String? _fcmToken;
  List<String> _firestoreTokens = const [];
  String? _currentUserId;
  bool _isLoading = false;
  bool _isSimulator = false;
  String _debugInfo = '';
  AuthorizationStatus? _notificationPermissionStatus;

  @override
  void initState() {
    super.initState();
    _checkEnvironment();
    _loadTokens();
  }

  /// 実行環境をチェック
  void _checkEnvironment() {
    if (kIsWeb) {
      _isSimulator = true;
      return;
    }

    try {
      if (Platform.isIOS) {
        _isSimulator = Platform.environment['SIMULATOR_DEVICE_NAME'] != null;
      } else if (Platform.isAndroid) {
        final model = Platform.environment['ANDROID_MODEL'] ?? '';
        final product = Platform.environment['ANDROID_PRODUCT'] ?? '';
        _isSimulator = model.toLowerCase().contains('sdk') ||
            product.toLowerCase().contains('sdk');
      }
    } catch (e) {
      _isSimulator = false;
    }
  }

  Future<void> _loadTokens() async {
    setState(() {
      _isLoading = true;
      _debugInfo = '';
    });

    try {
      // 現在のユーザーIDを取得
      final user = FirebaseAuth.instance.currentUser;
      _currentUserId = user?.uid;

      if (_currentUserId == null) {
        setState(() {
          _debugInfo = '❌ ユーザーがログインしていません';
        });
        return;
      }

      // 通知権限の状態を確認
      final messaging = FirebaseMessaging.instance;
      final notificationSettings = await messaging.getNotificationSettings();
      _notificationPermissionStatus = notificationSettings.authorizationStatus;

      // Android 13+の場合、詳細な権限デバッグログ
      if (Platform.isAndroid) {
        AppLogger.info('🐯 ANDROID FCM TOKEN取得開始');
        AppLogger.info('🔔 通知権限ステータス: $_notificationPermissionStatus');
        AppLogger.info('🔔 Alert権限: ${notificationSettings.alert}');
        AppLogger.info('🔔 Badge権限: ${notificationSettings.badge}');
        AppLogger.info('🔔 Sound権限: ${notificationSettings.sound}');

        // Android SDKバージョンの確認（可能であれば）
        try {
          final androidInfo = Platform.version;
          AppLogger.info('🤖 Android情報: $androidInfo');
        } catch (e) {
          AppLogger.info('🤖 Android情報取得エラー: $e');
        }
      }

      // FCMトークンを取得
      String? token;

      try {
        token = await messaging.getToken();
        if (token != null) {
          AppLogger.info('🐯 ANDROID FCM TOKEN: $token');
          AppLogger.info('🐯 トークン長: ${token.length}文字');
        } else {
          AppLogger.error('❌ ANDROID FCM TOKEN: null');
        }
      } catch (e) {
        AppLogger.error('❌ ANDROID FCM TOKEN取得エラー: $e');
        token = null;
      }

      // Firestoreに保存されているトークンを取得
      var firestoreTokens = const <String>[];
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId!)
            .get();

        if (userDoc.exists) {
          final rawTokens = userDoc.data()?['fcmTokens'];
          if (rawTokens is Iterable) {
            firestoreTokens = rawTokens
                .whereType<String>()
                .where((token) => token.isNotEmpty)
                .toSet()
                .toList(growable: false);
          }
        }
      } catch (e) {
        AppLogger.error('Firestoreからのトークン取得エラー: $e');
      }

      setState(() {
        _fcmToken = token;
        _firestoreTokens = firestoreTokens;

        // デバッグ情報を生成
        _debugInfo = _generateDebugInfo();
      });
    } catch (e) {
      AppLogger.error('トークン取得エラー: $e');
      setState(() {
        _debugInfo = '❌ エラー: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateDebugInfo() {
    final buffer = StringBuffer();

    buffer.writeln('📱 デバッグ情報:');
    buffer.writeln('ユーザーID: ${_currentUserId ?? "未取得"}');
    buffer.writeln('プラットフォーム: ${Platform.operatingSystem}');
    buffer.writeln('シミュレータ: ${_isSimulator ? "Yes" : "No"}');
    buffer.writeln('');

    // 通知権限の詳細情報
    buffer.writeln('🔔 通知権限情報:');
    if (_notificationPermissionStatus != null) {
      buffer.writeln(
          '権限ステータス: ${_getPermissionStatusText(_notificationPermissionStatus!)}');

      if (Platform.isAndroid) {
        buffer.writeln('');
        buffer.writeln('📋 Androidトラブルシューティング:');
        switch (_notificationPermissionStatus!) {
          case AuthorizationStatus.denied:
            buffer.writeln('❌ 通知権限が拒否されています');
            buffer.writeln('💡 設定 > アプリ > LaKiite > 通知 で許可してください');
            break;
          case AuthorizationStatus.notDetermined:
            buffer.writeln('❓ 通知権限が未決定です');
            buffer.writeln('💡 権限リクエストが必要です（Android 13+）');
            break;
          case AuthorizationStatus.authorized:
            buffer.writeln('✅ 通知権限が許可されています');
            break;
          case AuthorizationStatus.provisional:
            buffer.writeln('⚡ 仮許可状態です（iOS特有）');
            break;
        }
      }
    } else {
      buffer.writeln('権限ステータス: 取得中...');
    }
    buffer.writeln('');

    buffer.writeln('🔑 FCMトークン状況:');
    if (_fcmToken != null) {
      buffer.writeln('✅ FCMトークン取得: 成功');
      buffer.writeln('トークン長: ${_fcmToken!.length}文字');
    } else {
      buffer.writeln('❌ FCMトークン取得: 失敗');
    }

    buffer.writeln('');
    buffer.writeln('🗄️ Firestore保存状況:');
    if (_firestoreTokens.isNotEmpty) {
      buffer.writeln('✅ Firestoreにトークン保存済み');
      buffer.writeln('保存済みトークン数: ${_firestoreTokens.length}件');

      if (_fcmToken != null && _firestoreTokens.contains(_fcmToken)) {
        buffer.writeln('✅ トークン一致: OK');
      } else {
        buffer.writeln('⚠️ トークン不一致: 要更新');
      }
    } else {
      buffer.writeln('❌ Firestoreにトークン未保存');
    }

    return buffer.toString();
  }

  String _getPermissionStatusText(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return '✅ 許可済み';
      case AuthorizationStatus.denied:
        return '❌ 拒否';
      case AuthorizationStatus.notDetermined:
        return '❓ 未決定';
      case AuthorizationStatus.provisional:
        return '⚡ 仮許可';
    }
  }

  /// Android 13+の通知権限を手動でリクエストする
  Future<void> _requestNotificationPermission() async {
    try {
      setState(() {
        _isLoading = true;
      });

      AppLogger.info('🔔 通知権限の手動リクエストを開始');

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      AppLogger.info('🔔 権限リクエスト結果: ${settings.authorizationStatus}');

      // 状態を更新
      _notificationPermissionStatus = settings.authorizationStatus;

      // トークンを再取得
      await _loadTokens();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '権限リクエスト完了: ${_getPermissionStatusText(settings.authorizationStatus)}'),
            backgroundColor:
                settings.authorizationStatus == AuthorizationStatus.authorized
                    ? Colors.green
                    : Colors.orange,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('❌ 通知権限リクエストエラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('権限リクエストエラー: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('トークンをクリップボードにコピーしました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🐯 プッシュ通知デバッグ'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 説明
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'FCMトークンの確認',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Firebase Consoleからテスト通知を送信するために必要なトークンを表示します。',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // シミュレータ警告
            if (_isSimulator)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'シミュレータ環境を検出',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'シミュレータではプッシュ通知が制限されています。\n'
                        'FCMトークンの取得とプッシュ通知のテストには実機が必要です。',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isSimulator) const SizedBox(height: 16),

            // デバッグ情報表示
            if (_debugInfo.isNotEmpty)
              Card(
                color: Colors.purple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bug_report, color: Colors.purple.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'デバッグ情報',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SelectableText(
                          _debugInfo,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_debugInfo.isNotEmpty) const SizedBox(height: 16),

            // FCMトークン表示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '🐯 現在のFCMトークン',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_fcmToken != null)
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () => _copyToClipboard(_fcmToken!),
                            tooltip: 'コピー',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : SelectableText(
                              _fcmToken ?? 'トークンを取得できませんでした',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: _fcmToken != null
                                    ? Colors.black87
                                    : Colors.red,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Firestoreに保存されているトークン表示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '🗄️ Firestore保存トークン',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_firestoreTokens.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () =>
                                _copyToClipboard(_firestoreTokens.join('\n')),
                            tooltip: 'コピー',
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _firestoreTokens.isNotEmpty
                            ? (_fcmToken != null &&
                                    _firestoreTokens.contains(_fcmToken)
                                ? Colors.green.shade50
                                : Colors.orange.shade50)
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _firestoreTokens.isNotEmpty
                              ? (_fcmToken != null &&
                                      _firestoreTokens.contains(_fcmToken)
                                  ? Colors.green.shade300
                                  : Colors.orange.shade300)
                              : Colors.red.shade300,
                        ),
                      ),
                      child: SelectableText(
                        _firestoreTokens.isEmpty
                            ? 'Firestoreにトークンが保存されていません'
                            : _firestoreTokens.join('\n'),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: _firestoreTokens.isNotEmpty
                              ? Colors.black87
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 権限リクエストボタン（Android用）
            if (Platform.isAndroid &&
                _notificationPermissionStatus != AuthorizationStatus.authorized)
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _isLoading ? null : _requestNotificationPermission,
                    icon: const Icon(Icons.notifications_active),
                    label: const Text('通知権限をリクエスト'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),

            // 更新ボタン
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadTokens,
              icon: const Icon(Icons.refresh),
              label: const Text('トークンを更新'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            const SizedBox(height: 24),

            // 使用方法の説明
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.help_outline, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'テスト通知の送信方法',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. 上記のFCMトークンをコピー\n'
                      '2. Firebase Console → Cloud Messaging\n'
                      '3. "Send your first message" をクリック\n'
                      '4. 通知内容を入力\n'
                      '5. "Send test message" を選択\n'
                      '6. コピーしたトークンを貼り付けて送信',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.amber, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'アプリがバックグラウンド状態の時に通知が表示されます',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
