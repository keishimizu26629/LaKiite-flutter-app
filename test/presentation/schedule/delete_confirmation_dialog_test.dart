import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/presentation/calendar/widgets/delete_confirmation_dialog.dart';

void main() {
  testWidgets('削除確認Dialogは削除ボタンでコールバックを実行する', (tester) async {
    var deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeleteConfirmationDialog(
            title: 'コメントの削除',
            content: 'このコメントを削除してもよろしいですか？',
            onDelete: () => deleted = true,
          ),
        ),
      ),
    );

    expect(find.text('コメントの削除'), findsOneWidget);
    expect(find.text('このコメントを削除してもよろしいですか？'), findsOneWidget);

    await tester.tap(find.text('削除'));
    await tester.pumpAndSettle();

    expect(deleted, isTrue);
  });
}
