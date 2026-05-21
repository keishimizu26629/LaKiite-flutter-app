import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('layer dependencies', () {
    test('domain layer does not import outer layers', () {
      final domainFiles = Directory('lib/domain')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.endsWith('.g.dart'))
          .where((file) => !file.path.endsWith('.freezed.dart'));

      final violations = <String>[];

      for (final file in domainFiles) {
        final content = file.readAsStringSync();
        final forbiddenImports = RegExp(
          r'''import ['"]package:lakiite/(presentation|application|infrastructure)/|import ['"]\.\./\.\./(presentation|application|infrastructure)/|import ['"]\.\./(presentation|application|infrastructure)/''',
          multiLine: true,
        ).allMatches(content);

        for (final match in forbiddenImports) {
          violations.add('${file.path}: ${match.group(0)}');
        }
      }

      expect(violations, isEmpty);
    });

    test('application layer does not import presentation layer', () {
      final applicationFiles = Directory('lib/application')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.endsWith('.g.dart'))
          .where((file) => !file.path.endsWith('.freezed.dart'));

      final violations = <String>[];

      for (final file in applicationFiles) {
        final content = file.readAsStringSync();
        final forbiddenImports = RegExp(
          r'''import ['"]package:lakiite/presentation/|import ['"]\.\./\.\./presentation/|import ['"]\.\./presentation/''',
          multiLine: true,
        ).allMatches(content);

        for (final match in forbiddenImports) {
          violations.add('${file.path}: ${match.group(0)}');
        }
      }

      expect(violations, isEmpty);
    });

    test('unused group feature modules are not shipped', () {
      final removedFeaturePaths = [
        'lib/presentation/group',
        'lib/application/group',
        'lib/domain/service/group_manager.dart',
        'lib/domain/interfaces/i_group_repository.dart',
        'lib/infrastructure/group_repository.dart',
      ];

      final existingPaths = removedFeaturePaths.where((path) =>
          FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound);

      expect(existingPaths, isEmpty);
    });
  });
}
