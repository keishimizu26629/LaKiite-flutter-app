import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/firebase/push_notification_service.dart';
import '../../utils/logger.dart';

/// アプリライフサイクルの状態を管理するNotifier
class AppLifecycleNotifier extends StateNotifier<AppLifecycleState>
    with WidgetsBindingObserver {
  AppLifecycleNotifier() : super(AppLifecycleState.resumed) {
    WidgetsBinding.instance.addObserver(this);
    AppLogger.debug('AppLifecycleNotifier初期化完了');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    AppLogger.debug('アプリライフサイクル変更: ${state.name}');
    this.state = state;

    // フォアグラウンドに復帰した時にバッジをクリア
    if (state == AppLifecycleState.resumed) {
      _clearBadgeOnResume();
    }
  }

  /// フォアグラウンド復帰時にバッジをクリアする
  Future<void> _clearBadgeOnResume() async {
    try {
      AppLogger.info('🔄 フォアグラウンド復帰時のバッジクリアを実行...');
      await PushNotificationService.instance.clearBadgeCount();
      AppLogger.info('✅ フォアグラウンド復帰時のバッジクリア完了');
    } catch (e, stack) {
      AppLogger.error('フォアグラウンド復帰時のバッジクリアエラー: $e');
      AppLogger.error('スタックトレース: $stack');
    }
  }
}

/// アプリライフサイクル状態を提供するプロバイダー
final appLifecycleProvider =
    StateNotifierProvider<AppLifecycleNotifier, AppLifecycleState>(
  (ref) => AppLifecycleNotifier(),
);
