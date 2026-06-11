import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/presentation/settings/schedule_key_backup_page.dart';

void main() {
  Widget buildTestTarget() {
    return const MaterialApp(home: ScheduleKeyBackupPage());
  }

  testWidgets('引き継ぎパスワードと確認用パスワードの表示切替は独立している', (tester) async {
    await tester.pumpWidget(buildTestTarget());

    expect(tester.widget<TextField>(find.byType(TextField).at(0)).obscureText,
        isTrue);
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isTrue);

    await tester.tap(find.byTooltip('引き継ぎパスワードを表示'));
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField).at(0)).obscureText,
        isFalse);
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isTrue);

    await tester.tap(find.byTooltip('確認用パスワードを表示'));
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField).at(0)).obscureText,
        isFalse);
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isFalse);
  });

  testWidgets('既存の引き継ぎパスワードは保存時に上書きされることを表示する', (tester) async {
    await tester.pumpWidget(buildTestTarget());

    expect(find.textContaining('上書き'), findsOneWidget);
  });
}
