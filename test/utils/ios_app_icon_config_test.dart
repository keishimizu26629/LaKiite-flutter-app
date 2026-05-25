import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const xcodeProjectPath = 'ios/Runner.xcodeproj/project.pbxproj';
  const fastfilePath = 'ios/fastlane/Fastfile';

  test('iOS flavor build configurations use matching app icon sets', () {
    final project = File(xcodeProjectPath).readAsStringSync();

    _expectBuildConfigurationIcon(
      project,
      configurationName: 'Debug-dev',
      expectedIconName: 'AppIcon-development',
    );
    _expectBuildConfigurationIcon(
      project,
      configurationName: 'Release-dev',
      expectedIconName: 'AppIcon-development',
    );
    _expectBuildConfigurationIcon(
      project,
      configurationName: 'Profile-dev',
      expectedIconName: 'AppIcon-development',
    );
    _expectBuildConfigurationIcon(
      project,
      configurationName: 'Debug-prod',
      expectedIconName: 'AppIcon-production',
    );
    _expectBuildConfigurationIcon(
      project,
      configurationName: 'Release-prod',
      expectedIconName: 'AppIcon-production',
    );
    _expectBuildConfigurationIcon(
      project,
      configurationName: 'Profile-prod',
      expectedIconName: 'AppIcon-production',
    );
  });

  test('fastlane uploads use flavor-specific iOS schemes', () {
    final fastfile = File(fastfilePath).readAsStringSync();

    expect(fastfile, contains('ENV["SCHEME"] = "dev"'));
    expect(fastfile, contains('ENV["CONFIGURATION"] = "Release-dev"'));
    expect(fastfile, contains('ENV["SCHEME"] = "prod"'));
    expect(fastfile, contains('ENV["CONFIGURATION"] = "Release-prod"'));
    expect(
      fastfile,
      contains(
        'flutter build ios --release --flavor prod '
        '--dart-define-from-file=dart_define/prod_dart_define.json',
      ),
    );
  });
}

void _expectBuildConfigurationIcon(
  String project, {
  required String configurationName,
  required String expectedIconName,
}) {
  final icons = _targetBuildConfigurations(project)
      .where((settings) => settings['name'] == configurationName)
      .map((settings) => settings['ASSETCATALOG_COMPILER_APPICON_NAME'])
      .whereType<String>()
      .toSet();

  expect(
    icons,
    {expectedIconName},
    reason:
        '$configurationName must archive with $expectedIconName for App Store Connect.',
  );
}

List<Map<String, String>> _targetBuildConfigurations(String project) {
  final result = <Map<String, String>>[];

  for (final configuration in _runnerBuildConfigurationReferences(project)) {
    final settings = _extractBuildSettingsBlock(project, configuration.key);

    result.add({
      'name': configuration.value,
      'ASSETCATALOG_COMPILER_APPICON_NAME': _extractBuildSetting(
        settings,
        'ASSETCATALOG_COMPILER_APPICON_NAME',
      ),
    });
  }

  return result;
}

List<MapEntry<String, String>> _runnerBuildConfigurationReferences(
  String project,
) {
  final configurationList = RegExp(
    r'Build configuration list for PBXNativeTarget "Runner" \*/ = \{[\s\S]*?buildConfigurations = \((?<configs>[\s\S]*?)\);',
  ).firstMatch(project);

  if (configurationList == null) {
    throw StateError('Runner target build configuration list was not found.');
  }

  return RegExp(r'(?<id>[A-Z0-9]+) /\* (?<name>[^*]+) \*/')
      .allMatches(configurationList.namedGroup('configs')!)
      .map((match) {
    return MapEntry(
      match.namedGroup('id')!,
      match.namedGroup('name')!.trim(),
    );
  }).toList();
}

String _extractBuildSettingsBlock(String project, String configurationId) {
  final block = RegExp(
    '${RegExp.escape(configurationId)} /\\* [^*]+ \\*/ = \\{[\\s\\S]*?buildSettings = \\{(?<settings>[\\s\\S]*?)\\n\\t+\\};',
  ).firstMatch(project);

  if (block == null) {
    throw StateError(
        'Runner build configuration $configurationId was not found.');
  }

  return block.namedGroup('settings')!;
}

String _extractBuildSetting(String settings, String key) {
  final match = RegExp('$key = "?([^";]+)"?;').firstMatch(settings);
  if (match == null) {
    return '';
  }

  return match.group(1)!;
}
