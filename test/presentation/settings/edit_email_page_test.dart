import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/presentation/settings/edit_email_page.dart';

void main() {
  testWidgets('メールアドレス変更画面はフォーム下部に保存ボタンを表示する', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: EditEmailPage()));

    expect(
      find.byKey(const Key('edit-email-bottom-save-button')),
      findsOneWidget,
    );
  });

  testWidgets('メールアドレス形式エラーはメールアドレス欄に表示する', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: EditEmailPage()));

    await tester.enterText(
      find.byKey(const Key('edit-email-email-field')),
      'invalid-email',
    );
    await tester.enterText(
      find.byKey(const Key('edit-email-password-field')),
      'password123',
    );

    await tester.tap(find.byKey(const Key('edit-email-bottom-save-button')));
    await tester.pump();

    final emailField = tester.widget<TextField>(
      find.byKey(const Key('edit-email-email-field')),
    );
    final passwordField = tester.widget<TextField>(
      find.byKey(const Key('edit-email-password-field')),
    );

    expect(emailField.decoration?.errorText, '有効なメールアドレスを入力してください');
    expect(passwordField.decoration?.errorText, isNull);
  });
}
