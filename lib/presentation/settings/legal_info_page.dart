import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 法的情報（プライバシーポリシーや利用規約）を表示するページ
class LegalInfoPage extends StatefulWidget {
  /// 表示するページのタイトル
  final String title;

  /// 表示するURLパス
  final String urlPath;

  const LegalInfoPage({
    super.key,
    required this.title,
    required this.urlPath,
  });

  @override
  State<LegalInfoPage> createState() => _LegalInfoPageState();
}

class _LegalInfoPageState extends State<LegalInfoPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void dispose() {
    // WebViewControllerのリソースを適切に解放
    _controller.clearCache();
    _controller.clearLocalStorage();
    super.dispose();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://lakiite-flutter-app-prod.web.app/${widget.urlPath}'),
      );
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
      ),
    );
  }
}
