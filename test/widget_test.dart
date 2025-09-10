import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// シンプルなテスト用ウィジェット
class TestWidget extends StatelessWidget {
  const TestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Test Widget'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('基本的なウィジェットテスト', (WidgetTester tester) async {
    // 基本的なウィジェットが正常にレンダリングされることを確認
    await tester.pumpWidget(
      const ProviderScope(
        child: TestWidget(),
      ),
    );

    // テキストが表示されることを確認
    expect(find.text('Test Widget'), findsOneWidget);
  });
}
