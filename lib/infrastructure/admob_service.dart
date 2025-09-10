import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/logger.dart';

class AdMobService {
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // テスト用Android広告ユニットID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // テスト用iOS広告ユニットID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => AppLogger.debug('Ad loaded: ${ad.adUnitId}'),
        onAdFailedToLoad: (ad, error) {
          AppLogger.error('Ad failed to load: ${ad.adUnitId}, $error');
          ad.dispose();
        },
      ),
    );
  }

  static void dispose() {
    // リソースの解放処理
  }
}
