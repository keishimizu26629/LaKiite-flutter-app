import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../infrastructure/firebase/push_notification_service.dart';
import '../../utils/logger.dart';

/// デバッグ用：プッシュ通知トークン表示ページ
class DebugNotificationPage extends StatefulWidget {
  const DebugNotificationPage({super.key});

  @override
  State<DebugNotificationPage> createState() => _DebugNotificationPageState();
}

class _DebugNotificationPageState extends State<DebugNotificationPage> {
  String? _fcmToken;
  String? _apnsToken;
  bool _isLoading = false;
  bool _isSimulator = false;

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
    });

    try {
      final pushService = PushNotificationService.instance;
      final token = await pushService.getAndDisplayToken();

      setState(() {
        _fcmToken = token;
      });
    } catch (e) {
      AppLogger.error('トークン取得エラー: $e');
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
                          '🐯 FCM トークン',
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
