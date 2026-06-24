import 'dart:async';

import 'package:airbridge_flutter_sdk/airbridge_flutter_sdk.dart';

import '../utils/logger.dart';
import 'deep_link_navigation_service.dart';

class AirbridgeDeepLinkService {
  AirbridgeDeepLinkService({DeepLinkNavigationService? navigationService})
      : _navigationService =
            navigationService ?? DeepLinkNavigationService.instance;

  static final AirbridgeDeepLinkService instance = AirbridgeDeepLinkService();

  final DeepLinkNavigationService _navigationService;
  bool _isStarted = false;

  void start() {
    if (_isStarted) {
      return;
    }

    _isStarted = true;
    Airbridge.setOnDeeplinkReceived((deepLink) {
      AppLogger.info(
        'Airbridge Deep Linkを受信しました: ${_summarizeDeepLink(deepLink)}',
      );
      unawaited(_navigationService.handleReceivedDeepLink(deepLink));
    });
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
