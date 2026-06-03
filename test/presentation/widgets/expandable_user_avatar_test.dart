import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/presentation/widgets/expandable_user_avatar.dart';

void main() {
  group('ExpandableUserAvatar', () {
    testWidgets('画像URLありのアイコンをタップすると全画面で拡大表示する', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpandableUserAvatar(
              imageUrl: 'https://example.com/avatar.jpg',
              size: 80,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('expandable-user-avatar-button')));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).last);
      expect(scaffold.backgroundColor, Colors.black);
      expect(find.byType(PhotoView), findsOneWidget);
      expect(
          find.byKey(const Key('expanded-user-avatar-image')), findsOneWidget);
      expect(find.byTooltip('閉じる'), findsOneWidget);
    });

    testWidgets('画像URLがない場合はタップ対象にしない', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpandableUserAvatar(size: 80),
          ),
        ),
      );

      expect(
          find.byKey(const Key('expandable-user-avatar-button')), findsNothing);
      expect(find.byType(PhotoView), findsNothing);
    });
  });
}
