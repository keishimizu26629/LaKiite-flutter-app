import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const infoPlistPath = 'ios/Runner/Info.plist';
  const xcodeProjectPath = 'ios/Runner.xcodeproj/project.pbxproj';

  test('Info.plist resolves Google Mobile Ads app id from build settings', () {
    final infoPlist = File(infoPlistPath).readAsStringSync();

    expect(infoPlist, contains('<key>GADApplicationIdentifier</key>'));
    expect(
        infoPlist, contains('<string>\$(GAD_APPLICATION_IDENTIFIER)</string>'));
    expect(
      infoPlist,
      isNot(contains('ca-app-pub-3940256099942544~1458002511')),
      reason: 'Info.plist must not hard-code the development AdMob app id.',
    );
    expect(
      infoPlist,
      isNot(contains('ca-app-pub-6315199114988889~8448676824')),
      reason: 'Info.plist must not hard-code the production AdMob app id.',
    );
  });

  test('iOS build configurations use matching AdMob app ids', () {
    final devAdMobAppId =
        _readDartDefine('dart_define/dev_dart_define.json')['ADMOB_IOS_APP_ID'];
    final prodAdMobAppId = _readDartDefine(
        'dart_define/prod_dart_define.json')['ADMOB_IOS_APP_ID'];

    final project = File(xcodeProjectPath).readAsStringSync();
    final targetBuildSettings = _extractRunnerTargetBuildSettings(project);

    expect(targetBuildSettings, isNotEmpty);

    for (final buildSettings in targetBuildSettings) {
      final bundleId = buildSettings['PRODUCT_BUNDLE_IDENTIFIER'];
      final nativeAdMobAppId = buildSettings['GAD_APPLICATION_IDENTIFIER'];

      expect(
        nativeAdMobAppId,
        isNotEmpty,
        reason:
            'Every Runner target build configuration needs a native AdMob app id.',
      );

      if (bundleId == 'com.inoworl.lakiite.dev') {
        expect(nativeAdMobAppId, devAdMobAppId);
      } else if (bundleId == 'com.inoworl.lakiite') {
        expect(nativeAdMobAppId, prodAdMobAppId);
      } else {
        fail('Unexpected iOS bundle id: $bundleId');
      }
    }
  });
}

Map<String, dynamic> _readDartDefine(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
}

List<Map<String, String>> _extractRunnerTargetBuildSettings(String project) {
  final buildSettingsBlocks = RegExp(
    r'buildSettings = \{(?<settings>[\s\S]*?)\n\t+\};',
  ).allMatches(project);

  final result = <Map<String, String>>[];

  for (final match in buildSettingsBlocks) {
    final settings = match.namedGroup('settings')!;
    if (!settings.contains('PRODUCT_BUNDLE_IDENTIFIER')) {
      continue;
    }

    result.add({
      'PRODUCT_BUNDLE_IDENTIFIER':
          _extractBuildSetting(settings, 'PRODUCT_BUNDLE_IDENTIFIER'),
      'GAD_APPLICATION_IDENTIFIER':
          _extractBuildSetting(settings, 'GAD_APPLICATION_IDENTIFIER'),
    });
  }

  return result;
}

String _extractBuildSetting(String settings, String key) {
  final match = RegExp('$key = "?([^";]+)"?;').firstMatch(settings);
  if (match == null) {
    return '';
  }

  return match.group(1)!;
}
