import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('設定画面に使い方リンクを表示する', () {
    final source =
        File('lib/presentation/settings/settings_page.dart').readAsStringSync();

    expect(source, contains("title: const Text('使い方')"));
    expect(source, contains("context.push('/settings/how-to-use')"));
  });
}
