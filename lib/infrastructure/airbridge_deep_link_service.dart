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
      AppLogger.info('Airbridge Deep Linkを受信しました');
      unawaited(_navigationService.handleReceivedDeepLink(deepLink));
    });
  }
}
