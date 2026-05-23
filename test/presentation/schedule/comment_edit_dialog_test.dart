import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/presentation/calendar/widgets/comment_edit_dialog.dart';

void main() {
  testWidgets('コメント編集Dialogは初期値を表示し、保存で入力内容を返す', (tester) async {
    String? savedContent;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommentEditDialog(
            initialContent: '元のコメント',
            onSave: (content) => savedContent = content,
          ),
        ),
      ),
    );

    expect(find.text('コメントの編集'), findsOneWidget);
    expect(find.text('元のコメント'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '更新後のコメント');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(savedContent, '更新後のコメント');
  });

  testWidgets('コメント編集Dialogは空白だけの入力を保存しない', (tester) async {
    var saveCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommentEditDialog(
            initialContent: '元のコメント',
            onSave: (_) => saveCount++,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('保存'));
    await tester.pump();

    expect(saveCount, 0);
  });
}
