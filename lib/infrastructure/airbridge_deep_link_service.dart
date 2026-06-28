import 'dart:async';

import 'package:airbridge_flutter_sdk/airbridge_flutter_sdk.dart';
import 'package:flutter/services.dart';

import '../utils/logger.dart';
import 'deep_link_navigation_service.dart';

class AirbridgeDeepLinkService {
  AirbridgeDeepLinkService({
    DeepLinkNavigationService? navigationService,
    MethodChannel? nativeDeepLinkChannel,
    bool enableAirbridgeRuntime = true,
  })  : _navigationService =
            navigationService ?? DeepLinkNavigationService.instance,
        _nativeDeepLinkChannel =
            nativeDeepLinkChannel ?? _defaultNativeDeepLinkChannel,
        _enableAirbridgeRuntime = enableAirbridgeRuntime;

  static final AirbridgeDeepLinkService instance = AirbridgeDeepLinkService();
  static const MethodChannel _defaultNativeDeepLinkChannel =
      MethodChannel('lakiite/deep_link');

  final DeepLinkNavigationService _navigationService;
  final MethodChannel _nativeDeepLinkChannel;
  final bool _enableAirbridgeRuntime;
  bool _isStarted = false;

  void start() {
    if (_isStarted) {
      return;
    }

    _isStarted = true;
    AppLogger.info('Deep Link監視を開始しました');
    if (_enableAirbridgeRuntime) {
      Airbridge.setOnDeeplinkReceived((deepLink) {
        AppLogger.info(
          'Airbridge Deep Linkを受信しました: ${_summarizeDeepLink(deepLink)}',
        );
        unawaited(_navigationService.handleReceivedDeepLink(deepLink));
      });
    }
    unawaited(_startNativeDeepLinkFallback());
  }

  Future<void> _startNativeDeepLinkFallback() async {
    _nativeDeepLinkChannel.setMethodCallHandler((call) async {
      if (call.method != 'onDeepLink') {
        throw MissingPluginException(
          '未対応のNative Deep Link methodです: ${call.method}',
        );
      }

      final deepLink = call.arguments;
      if (deepLink is! String) {
        AppLogger.warning('Native Deep Linkの引数が文字列ではありません');
        return null;
      }

      _handleNativeDeepLink(deepLink);
      return null;
    });

    try {
      final initialDeepLink = await _nativeDeepLinkChannel.invokeMethod<String>(
        'getInitialDeepLink',
      );
      _handleNativeDeepLink(initialDeepLink);
    } on MissingPluginException {
      AppLogger.debug('Native Deep Link channelは未実装です');
    } catch (e) {
      AppLogger.warning('Native Deep Linkの初期取得に失敗しました: $e');
    }
  }

  void _handleNativeDeepLink(String? deepLink) {
    final trimmedDeepLink = deepLink?.trim();
    if (trimmedDeepLink == null || trimmedDeepLink.isEmpty) {
      return;
    }

    AppLogger.info(
      'Native Deep Linkを受信しました: ${_summarizeDeepLink(trimmedDeepLink)}',
    );
    unawaited(_navigationService.handleReceivedDeepLink(trimmedDeepLink));
  }

  String _summarizeDeepLink(String deepLink) {
    final uri = Uri.tryParse(deepLink);
    if (uri == null) {
      return 'invalid_uri';
    }

    final queryKeys = uri.queryParametersAll.keys.toList()..sort();
    final queryKeySummary = queryKeys.isEmpty ? '-' : queryKeys.join(',');
    final scheme = uri.scheme.isEmpty ? '-' : uri.scheme;
    final host = uri.host.isEmpty ? '-' : uri.host;
    final path = uri.path.isEmpty ? '/' : uri.path;

    return 'scheme=$scheme host=$host path=$path queryKeys=$queryKeySummary';
  }
}
