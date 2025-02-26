import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      // ignore: deprecated_member_use
      printTime: true,
    ),
  );

  // 予定作成関連のファイルパスリスト
  static const _enabledPaths = [
    'schedule_form_page.dart',
    'schedule_repository.dart',
    'schedule_notifier.dart'
  ];

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

  static void debug(dynamic message) {
    final filePath = _getFilePath();
    if (_enabledPaths.contains(filePath)) {
      // ignore: avoid_print
      print('🔵 [${filePath.split('.').first}] $message');
    }
  }

  static void info(dynamic message) {
    final filePath = _getFilePath();
    if (_enabledPaths.contains(filePath)) {
      // ignore: avoid_print
      print('ℹ️ [${filePath.split('.').first}] $message');
    }
  }

  static void warning(dynamic message) {
    final filePath = _getFilePath();
    if (_enabledPaths.contains(filePath)) {
      // ignore: avoid_print
      print('⚠️ [${filePath.split('.').first}] $message');
    }
  }

  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final filePath = _getFilePath();
    if (_enabledPaths.contains(filePath)) {
      // ignore: avoid_print
      print('🔴 [${filePath.split('.').first}] $message');
      // ignore: avoid_print
      if (error != null) print('Error: $error');
      // ignore: avoid_print
      if (stackTrace != null) print('StackTrace: $stackTrace');
    }
  }
}
