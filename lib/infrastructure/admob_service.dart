import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/admob_config.dart';
import '../utils/logger.dart';

class AdMobService {
  /// 環境に応じたAdMobアプリIDを取得
  static String get appId => AdMobConfig.instance.getAppId();

  /// 環境に応じたバナー広告ユニットIDを取得
  static String get bannerAdUnitId => AdMobConfig.instance.getBannerId();

  static Future<void> initialize() async {
    AppLogger.info('🎯 AdMob初期化開始...');
    AppLogger.info('📱 使用中のApp ID: $appId');
    AppLogger.info('🎪 使用中のBanner ID: $bannerAdUnitId');

    await MobileAds.instance.initialize();
    AppLogger.info('✅ AdMob初期化完了');
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
