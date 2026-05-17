import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const manifestPath = 'android/app/src/main/AndroidManifest.xml';
  const buildGradlePath = 'android/app/build.gradle';

  test(
      'AndroidManifest resolves Google Mobile Ads app id from flavor placeholders',
      () {
    final manifest = File(manifestPath).readAsStringSync();

    expect(manifest, contains('com.google.android.gms.ads.APPLICATION_ID'));
    expect(manifest, contains(r'android:value="${adMobApplicationId}"'));
    expect(
      manifest,
      isNot(contains('ca-app-pub-3940256099942544~3347511713')),
      reason:
          'AndroidManifest.xml must not hard-code the development AdMob app id.',
    );
    expect(
      manifest,
      isNot(contains('ca-app-pub-6315199114988889~9761758494')),
      reason:
          'AndroidManifest.xml must not hard-code the production AdMob app id.',
    );
  });

  test('Android flavors use matching AdMob app ids', () {
    final devAdMobAppId = _readDartDefine(
      'dart_define/dev_dart_define.json',
    )['ADMOB_ANDROID_APP_ID'];
    final prodAdMobAppId = _readDartDefine(
      'dart_define/prod_dart_define.json',
    )['ADMOB_ANDROID_APP_ID'];

    final buildGradle = File(buildGradlePath).readAsStringSync();

    expect(_extractFlavorAdMobAppId(buildGradle, 'dev'), devAdMobAppId);
    expect(_extractFlavorAdMobAppId(buildGradle, 'prod'), prodAdMobAppId);
  });
}

Map<String, dynamic> _readDartDefine(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

String _extractFlavorAdMobAppId(String buildGradle, String flavor) {
  final flavorBlock = RegExp(
    '$flavor \\{(?<settings>[\\s\\S]*?)\\n        \\}',
  ).firstMatch(buildGradle);

  if (flavorBlock == null) {
    fail('Missing Android flavor block: $flavor');
  }

  final settings = flavorBlock.namedGroup('settings')!;
  final appId = RegExp(
    r'adMobApplicationId:\s*"([^"]+)"',
  ).firstMatch(settings);

  if (appId == null) {
    fail('Missing adMobApplicationId for Android flavor: $flavor');
  }

  return appId.group(1)!;
}
