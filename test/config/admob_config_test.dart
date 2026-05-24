import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/config/admob_config.dart';

void main() {
  group('AdMobConfig', () {
    test('TEST_MODEではAdMobの実設定を要求しない', () {
      expect(() => AdMobConfig.initialize(), returnsNormally);
      expect(AdMobConfig.instance.androidAppId, 'ca-app-pub-test-android');
      expect(AdMobConfig.instance.iosAppId, 'ca-app-pub-test-ios');
    });
  });
}
