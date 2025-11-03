import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../application/auth/auth_notifier.dart';
import '../../utils/logger.dart';
import '../login/login_page.dart';

/// WebViewベースのアカウント削除ページ
class AccountDeletionWebViewPage extends ConsumerStatefulWidget {
  const AccountDeletionWebViewPage({super.key});

  static const String path = '/account-deletion-webview';

  @override
  ConsumerState<AccountDeletionWebViewPage> createState() => _AccountDeletionWebViewPageState();
}

class _AccountDeletionWebViewPageState extends ConsumerState<AccountDeletionWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _initWebView() {
    try {
      if (_isDisposed) {
        AppLogger.warning('Attempted to initialize WebView after disposal');
        return;
      }

      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted && !_isDisposed) {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted && !_isDisposed) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              AppLogger.error('WebView error: ${error.description}');
              if (mounted && !_isDisposed) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                  _errorMessage = 'エラーが発生しました: ${error.description}';
                });
              }
            },
          ),
        )
        ..addJavaScriptChannel(
          'deleteAccount',
          onMessageReceived: (JavaScriptMessage message) {
            _handleDeleteAccount(message.message);
          },
        )
        ..addJavaScriptChannel(
          'deletionComplete',
          onMessageReceived: (JavaScriptMessage message) {
            _handleDeletionComplete();
          },
        )
        ..addJavaScriptChannel(
          'cancelDeletion',
          onMessageReceived: (JavaScriptMessage message) {
            _handleCancelDeletion();
          },
        )
        ..addJavaScriptChannel(
          'pageReady',
          onMessageReceived: (JavaScriptMessage message) {
            AppLogger.debug('WebView page ready');
          },
        );

      // マウント状態を確認してからURLをロード
      if (mounted && !_isDisposed) {
        _controller.loadRequest(
          Uri.parse('https://keishimizu26629.github.io/LaKiite-flutter-app/account-deletion-webview.html'),
        );
      }
    } catch (e) {
      AppLogger.error('WebViewController initialization error: ${e.toString()}');
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'WebViewの初期化に失敗しました: ${e.toString()}';
        });
      }
    }
  }

  /// アカウント削除リクエストを処理
  Future<void> _handleDeleteAccount(String message) async {
    try {
      AppLogger.debug('Delete account request received: $message');

      // メッセージをパース（JSON形式を想定）
      // 実際の実装では、パスワード再認証を含む削除処理を実行
      final authNotifier = ref.read(authNotifierProvider.notifier);

      // 削除処理を実行
      await authNotifier.deleteAccount();

      // 成功をWebViewに通知
      await _controller.runJavaScript('''
        if (window.requestAccountDeletion) {
          window.requestAccountDeletion().then(function(resolve) {
            resolve({ success: true });
          });
        }
      ''');

      AppLogger.info('Account deletion completed successfully');
    } catch (e) {
      AppLogger.error('Account deletion failed: $e');

      // エラーをWebViewに通知
      await _controller.runJavaScript('''
        if (window.requestAccountDeletion) {
          window.requestAccountDeletion().then(function(resolve) {
            resolve({ success: false, error: "${e.toString()}" });
          });
        }
      ''');
    }
  }

  /// 削除完了後の処理
  void _handleDeletionComplete() {
    AppLogger.info('Account deletion process completed');

    if (mounted) {
      // ログイン画面に遷移
      context.go(LoginPage.path);

      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('アカウントが正常に削除されました'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// キャンセル処理
  void _handleCancelDeletion() {
    AppLogger.debug('Account deletion cancelled');

    if (mounted) {
      // 前の画面に戻る
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント削除'),
        backgroundColor: Colors.red.shade50,
        foregroundColor: Colors.red.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorView();
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) _buildLoadingView(),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
            ),
            SizedBox(height: 16),
            Text(
              'アカウント削除ページを読み込み中...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'ページの読み込みに失敗しました',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('戻る'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _initWebView,
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
