import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:lakiite/infrastructure/admob_service.dart';

final bannerAdProvider = Provider.autoDispose((ref) {
  final bannerAd = AdMobService.createBannerAd();
  bannerAd.load();
  ref.onDispose(() {
    bannerAd.dispose();
  });
  return bannerAd;
});

class BannerAdWidget extends ConsumerWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerAd = ref.watch(bannerAdProvider);

    return Container(
      alignment: Alignment.center,
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }
}
