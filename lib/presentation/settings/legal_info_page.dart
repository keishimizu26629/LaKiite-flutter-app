import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../utils/logger.dart';

/// 法的情報（プライバシーポリシーや利用規約）を表示するページ
class LegalInfoPage extends StatefulWidget {
  const LegalInfoPage({
    super.key,
    required this.title,
    required this.urlPath,
  });

  /// 表示するページのタイトル
  final String title;

  /// 表示するURLパス
  final String urlPath;

  @override
  State<LegalInfoPage> createState() => _LegalInfoPageState();
}

class _LegalInfoPageState extends State<LegalInfoPage> {
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
    // メモリリークを防ぐため、明示的にControllerをクリーンアップ
    _isDisposed = true;

    // WebViewのリソース解放を安全に行う
    try {
      // controllerの各操作を個別のtry-catchで囲む
      try {
        _controller.clearCache();
      } catch (e) {
        AppLogger.error('Failed to clear cache: ${e.toString()}');
      }

      try {
        _controller.clearLocalStorage();
      } catch (e) {
        AppLogger.error('Failed to clear local storage: ${e.toString()}');
      }

      // WebView関連の追加クリーンアップ
      try {
        _controller.setNavigationDelegate(NavigationDelegate());
      } catch (e) {
        AppLogger.error('Failed to reset navigation delegate: ${e.toString()}');
      }

      // バックグラウンドプロセスやリソースを解放
      try {
        _controller.setJavaScriptMode(JavaScriptMode.disabled);
      } catch (e) {
        AppLogger.error('Failed to disable JavaScript: ${e.toString()}');
      }
    } catch (e) {
      AppLogger.error('WebView disposal error: ${e.toString()}');
    }

    super.dispose();
  }

  void _initWebView() {
    try {
      // WebViewControllerの初期化チェック
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
        );

      // マウント状態を確認してからURLをロード
      if (mounted && !_isDisposed) {
        _controller.loadRequest(
          Uri.parse(
              'https://keishimizu26629.github.io/LaKiite-flutter-app/${widget.urlPath}.html'),
        );
      }
    } catch (e) {
      AppLogger.error(
          'WebViewController initialization error: ${e.toString()}');
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'WebViewの初期化に失敗しました: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // エラーが発生した場合はエラーメッセージを表示
            if (_hasError)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (!_isDisposed) {
                            setState(() {
                              _hasError = false;
                              _isLoading = true;
                              _initWebView();
                            });
                          }
                        },
                        child: const Text('再読み込み'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Stack(
                children: [
                  // WebViewが表示されていない場合は空のコンテナを表示
                  if (_isLoading)
                    Container(
                      color: Colors.white,
                    ),
                  // WebViewを表示
                  WebViewWidget(controller: _controller),
                  // ローディング中はプログレスインジケータを表示
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
