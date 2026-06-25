import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('設定画面に使い方リンクを表示する', () {
    final source =
        File('lib/presentation/settings/settings_page.dart').readAsStringSync();

    expect(source, contains("title: const Text('使い方')"));
    expect(source, contains("context.push('/settings/how-to-use')"));
  });

  test('端末引き継ぎ設定の設定状態を表示する', () {
    final source =
        File('lib/presentation/settings/settings_page.dart').readAsStringSync();

    expect(source, contains('設定済み'));
    expect(source, contains('未設定'));
    expect(source, contains('schedulePrivateKeyBackupExistsProvider'));
  });

  test('端末引き継ぎの案内文に未実装予定の文言を残さない', () {
    final source =
        File('lib/presentation/encryption/schedule_private_key_gate.dart')
            .readAsStringSync();

    expect(source, isNot(contains('Phase2で実装予定')));
  });
}
