class AppLogger {
  // デバッグログを有効にするファイルパスリスト
  static const _enabledPaths = [
    'schedule_form_page.dart',
    'schedule_repository.dart',
    'schedule_notifier.dart',
    'calendar_page_view.dart',
    'daily_schedule_view.dart',
    'firebase_storage_service.dart',
    'my_page_view_model.dart',
    'storage_service.dart',
    'image_processor_service.dart',
    'schedule_interaction_repository.dart',
    'schedule_interaction_notifier.dart',
    'schedule_detail_page.dart'
  ];

  // 常にログを表示するかどうか
  static const bool _alwaysShowLogs = true;

  // テスト環境かどうかを判定
  static bool get _isTestEnvironment {
    try {
      // Flutter Test環境では特定の条件をチェック
      return const bool.fromEnvironment('flutter.inspector.structuredErrors') ||
          const bool.fromEnvironment('FLUTTER_TEST') ||
          StackTrace.current.toString().contains('flutter_test');
    } catch (e) {
      return false;
    }
  }

  // スタックトレースからファイルパスを取得
  static String _getFilePath() {
    try {
      final frames = StackTrace.current.toString().split('\n');
      for (final frame in frames) {
        for (final path in _enabledPaths) {
          if (frame.toLowerCase().contains(path.toLowerCase())) {
            return path;
          }
        }
      }
    } catch (e) {
      return '';
    }
    return '';
  }

  // スタックトレースを短縮して返す（最初の3行だけ）
  static String _formatStackTrace(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    final shortened = lines.take(3).join('\n');
    return shortened;
  }

  static void debug(dynamic message) {
    // テスト環境ではdebugログを出力しない
    if (_isTestEnvironment) return;

    final filePath = _getFilePath();
    if (_alwaysShowLogs || _enabledPaths.contains(filePath)) {
      // ignore: avoid_print
      print(
          '🔵 [DEBUG] [${filePath.isEmpty ? 'App' : filePath.split('.').first}] $message');
    }
  }

  static void info(dynamic message) {
    // テスト環境ではinfoログを出力しない
    if (_isTestEnvironment) return;

    final filePath = _getFilePath();
    if (_alwaysShowLogs || _enabledPaths.contains(filePath)) {
      // ignore: avoid_print
      print(
          'ℹ️ [INFO] [${filePath.isEmpty ? 'App' : filePath.split('.').first}] $message');
    }
  }

  static void warning(dynamic message) {
    final filePath = _getFilePath();
    if (_alwaysShowLogs || _enabledPaths.contains(filePath)) {
      // ignore: avoid_print
      print(
          '⚠️ [WARN] [${filePath.isEmpty ? 'App' : filePath.split('.').first}] $message');
    }
  }

  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final filePath = _getFilePath();
    if (_alwaysShowLogs || _enabledPaths.contains(filePath)) {
      // エラーメッセージを簡潔にする
      String errorMsg = message.toString();
      // メッセージが長すぎる場合は切り詰める
      if (errorMsg.length > 150) {
        errorMsg = '${errorMsg.substring(0, 147)}...';
      }

      // ignore: avoid_print
      print(
          '🔴 [ERROR] [${filePath.isEmpty ? 'App' : filePath.split('.').first}] $errorMsg');

      // エラーオブジェクトがある場合、短く表示
      if (error != null) {
        String errorDetail = error.toString();
        if (errorDetail.length > 150) {
          errorDetail = '${errorDetail.substring(0, 147)}...';
        }
        // ignore: avoid_print
        print('Error: $errorDetail');
      }

      // スタックトレースは最初の数行だけ表示
      if (stackTrace != null) {
        // ignore: avoid_print
        print('StackTrace: ${_formatStackTrace(stackTrace)}');
      }
    }
  }
}
