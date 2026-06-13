import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/presentation/widgets/reaction_icon_widget.dart';

void main() {
  testWidgets('両方のリアクションがある場合は中央基準で重ねて表示する', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: ReactionIconWidget(
          hasGoing: true,
          hasThinking: true,
        ),
      ),
    );

    final stack = tester.widget<Stack>(find.byType(Stack));

    expect(stack.alignment, Alignment.center);
    expect(stack.clipBehavior, Clip.none);
    expect(find.byType(Positioned), findsNothing);
    expect(find.byType(Transform), findsNWidgets(2));
    expect(find.text('🙋'), findsOneWidget);
    expect(find.text('🤔'), findsOneWidget);

    final thinkingTransform = tester.widget<Transform>(find.ancestor(
      of: find.text('🤔'),
      matching: find.byType(Transform),
    ));
    final goingTransform = tester.widget<Transform>(find.ancestor(
      of: find.text('🙋'),
      matching: find.byType(Transform),
    ));

    final thinkingOffset =
        MatrixUtils.getAsTranslation(thinkingTransform.transform);
    final goingOffset = MatrixUtils.getAsTranslation(goingTransform.transform);

    expect(thinkingOffset!.dy, goingOffset!.dy);
  });
}
