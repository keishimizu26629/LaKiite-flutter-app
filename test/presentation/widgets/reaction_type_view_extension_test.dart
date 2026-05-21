import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/presentation/widgets/reaction_type_view_extension.dart';

void main() {
  group('ReactionTypeViewX', () {
    test('UI表示に必要なラベルと絵文字をenumから取得できる', () {
      expect(ReactionType.going.label, '行きます！');
      expect(ReactionType.going.emoji, '🙋');
      expect(ReactionType.thinking.label, '考え中！');
      expect(ReactionType.thinking.emoji, '🤔');
    });
  });
}
