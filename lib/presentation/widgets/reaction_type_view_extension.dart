import 'package:lakiite/domain/entity/schedule_reaction.dart';

/// [ReactionType] を UI 表示用の値に変換する拡張。
extension ReactionTypeViewX on ReactionType {
  /// リアクション選択 UI や表示テキストで使うラベル。
  String get label => switch (this) {
        ReactionType.going => '行きます！',
        ReactionType.thinking => '考え中！',
      };

  /// リアクションを短く表現する絵文字。
  String get emoji => switch (this) {
        ReactionType.going => '🙋',
        ReactionType.thinking => '🤔',
      };
}
