import 'logger.dart';

/// WebViewインスタンスの監視と管理を行うクラス
///
/// iOS でのクラッシュ対策として、WebView インスタンスの
/// 作成・破棄を追跡し、適切なクリーンアップを支援します
class WebViewMonitor {
  static final List<String> _activeWebViews = [];

  /// WebViewインスタンスを登録
  ///
  /// [id] WebViewの識別子
  static void registerWebView(String id) {
    _activeWebViews.add(id);
    AppLogger.debug(
        'WebView registered: $id (total: ${_activeWebViews.length})');
  }

  /// WebViewインスタンスを登録解除
  ///
  /// [id] WebViewの識別子
  static void unregisterWebView(String id) {
    _activeWebViews.remove(id);
    AppLogger.debug(
        'WebView unregistered: $id (total: ${_activeWebViews.length})');
  }

  /// アクティブなWebViewの一覧を取得
  ///
  /// 戻り値: アクティブなWebViewのID一覧
  static List<String> getActiveWebViews() => List.from(_activeWebViews);

  /// すべてのWebViewインスタンスをクリア
  ///
  /// 認証状態の変更時などに使用
  static void clearAll() {
    AppLogger.warning(
        'Clearing all WebView instances: ${_activeWebViews.length}');
    _activeWebViews.clear();
  }

  /// 未解放のWebViewインスタンスがあるかチェック
  ///
  /// 戻り値: 未解放のインスタンスがある場合 true
  static bool hasUnreleasedInstances() {
    final hasUnreleased = _activeWebViews.isNotEmpty;
    if (hasUnreleased) {
      AppLogger.warning('未解放のWebViewインスタンス: ${_activeWebViews.length}個');
      for (final id in _activeWebViews) {
        AppLogger.warning('- $id');
      }
    }
    return hasUnreleased;
  }

  /// デバッグ情報を出力
  static void printStatus() {
    AppLogger.debug('WebView Status:');
    AppLogger.debug('- Active instances: ${_activeWebViews.length}');
    for (final id in _activeWebViews) {
      AppLogger.debug('  - $id');
    }
  }
}
