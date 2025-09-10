import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/logger.dart';

/// 法的情報（プライバシーポリシーや利用規約）を表示するための代替ページ
/// WebViewの代わりにURLランチャーを使用して外部ブラウザで表示します
class LegalInfoPageAlternative extends StatelessWidget {
  /// プライバシーポリシーのパス
  static const String privacyPolicyPath = 'privacy-policy';

  /// 利用規約のパス
  static const String termsOfServicePath = 'terms-of-service';

  /// 表示するページのタイトル
  final String title;

  /// 表示するURLパス
  final String urlPath;

  const LegalInfoPageAlternative({
    super.key,
    required this.title,
    required this.urlPath,
  });

  @override
  Widget build(BuildContext context) {
    final url = 'https://keishimizu26629.github.io/LaKiite-flutter-app/$urlPath.html';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.article_outlined,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                '$titleを表示します',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _launchURL(context, url),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('ブラウザで開く'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 指定されたURLを外部ブラウザで開く
  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
            enableDomStorage: true,
          ),
        );
      } else {
        // URLを開けない場合はスナックバーでエラーを表示
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('URLを開けませんでした: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
        AppLogger.error('Could not launch $url');
      }
    } catch (e) {
      // 例外が発生した場合もスナックバーでエラーを表示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      AppLogger.error('Error launching URL: $e');
    }
  }
}
