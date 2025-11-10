import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lakiite/infrastructure/admob_service.dart';

// 各ウィジェットインスタンスごとに新しいBannerAdを作成するためのファミリープロバイダー
final bannerAdProvider =
    Provider.autoDispose.family<BannerAd, String>((ref, id) {
  final bannerAd = AdMobService.createBannerAd();
  bannerAd.load();
  ref.onDispose(() {
    bannerAd.dispose();
  });
  return bannerAd;
});

class BannerAdWidget extends ConsumerWidget {
  const BannerAdWidget({
    super.key,
    required this.uniqueId,
  });

  // 一意のIDを追加
  final String uniqueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 一意のIDを使用して独自のBannerAdを取得
    final bannerAd = ref.watch(bannerAdProvider(uniqueId));

    return Container(
      alignment: Alignment.center,
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }
}
