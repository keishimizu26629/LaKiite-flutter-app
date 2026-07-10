import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const xcodeProjectPath = 'ios/Runner.xcodeproj/project.pbxproj';
  const devIosWorkflowPath = '.github/workflows/deploy_dev_ios.yml';
  const prodIosWorkflowPath = '.github/workflows/deploy_prod_ios.yml';

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

  test('iOS release workflows use flavor-specific build settings', () {
    final devWorkflow = File(devIosWorkflowPath).readAsStringSync();
    final prodWorkflow = File(prodIosWorkflowPath).readAsStringSync();

    expect(devWorkflow,
        contains('cp ios/DevExportOptions.plist ios/ExportOptions.plist'));
    expect(devWorkflow, contains('--flavor dev'));
    expect(devWorkflow,
        contains('--dart-define-from-file="dart_define/dev_dart_define.json"'));
    expect(devWorkflow, contains('-scheme dev'));
    expect(devWorkflow, contains('-configuration Release-dev'));

    expect(prodWorkflow,
        contains('cp ios/ProdExportOptions.plist ios/ExportOptions.plist'));
    expect(prodWorkflow, contains('--flavor prod'));
    expect(
        prodWorkflow, contains('--dart-define-from-file="dart_define.json"'));
    expect(prodWorkflow, contains('-scheme prod'));
    expect(prodWorkflow, contains('-configuration Release-prod'));
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
