import 'package:flutter/material.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';

/// リアクションアイコンを表示するウィジェット
///
/// リアクションの種類に応じて適切なアイコンを表示します。
/// `hasGoing`（行きます！）と`hasThinking`（考え中！）の2種類のリアクションの
/// 有無に基づいて表示パターンを切り替えます。
///
/// 表示パターン:
/// - 両方のリアクションがある場合: 重なり合ったアイコンを表示
/// - 「行きます！」のみの場合: 🙋のアイコンを中央に表示
/// - 「考え中！」のみの場合: 🤔のアイコンを中央に表示
/// - どちらもない場合: 指定された内容を表示
///
/// また、`isLoading`パラメータがtrueの場合はローディングインジケータを表示します。
class ReactionIconWidget extends StatelessWidget {
  /// コンストラクタ
  ///
  /// [hasGoing] 「行きます！」リアクションの有無
  /// [hasThinking] 「考え中！」リアクションの有無
  /// [iconSize] アイコンサイズ（デフォルト: 20）
  /// [isLoading] ローディング状態の有無（デフォルト: false）
  const ReactionIconWidget({
    super.key,
    required this.hasGoing,
    required this.hasThinking,
    this.iconSize = 20,
    this.isLoading = false,
  });

  /// 「行きます！」リアクションの有無
  final bool hasGoing;

  /// 「考え中！」リアクションの有無
  final bool hasThinking;

  /// アイコンの表示サイズ
  final double iconSize;

  /// ローディング中かどうかのフラグ
  final bool isLoading;

  /// ScheduleInteractionStateのリアクションカウントデータからインスタンスを生成するファクトリメソッド
  ///
  /// [reactionCounts] リアクション種類ごとのカウント情報を含むマップ
  /// [iconSize] アイコンサイズ（デフォルト: 20）
  /// [isLoading] ローディング状態の有無（デフォルト: false）
  ///
  /// マップ内のリアクションカウントに基づいて`hasGoing`と`hasThinking`を自動的に判定します。
  // ignore: sort_constructors_first
  factory ReactionIconWidget.fromReactionCounts(
    Map<ReactionType, int> reactionCounts, {
    double iconSize = 20,
    bool isLoading = false,
  }) {
    final hasGoing = reactionCounts[ReactionType.going] != null &&
        reactionCounts[ReactionType.going]! > 0;
    final hasThinking = reactionCounts[ReactionType.thinking] != null &&
        reactionCounts[ReactionType.thinking]! > 0;

    return ReactionIconWidget(
      hasGoing: hasGoing,
      hasThinking: hasThinking,
      iconSize: iconSize,
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ローディング状態の表示
    if (isLoading) {
      return SizedBox(
        width: iconSize * 1.5,
        height: iconSize * 1.5,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    // リアクションの種類に基づいて表示を切り替え
    if (hasGoing && hasThinking) {
      // 両方のリアクションがある場合は重なり合ったアイコンを表示
      return Stack(
        children: [
          Positioned(
            right: 2,
            child: Text(
              '🤔',
              style: TextStyle(
                fontSize: iconSize,
              ),
            ),
          ),
          Positioned(
            top: -1,
            left: -2,
            child: Text(
              '🙋',
              style: TextStyle(
                fontSize: iconSize,
              ),
            ),
          ),
        ],
      );
    } else if (hasGoing) {
      // 「行きます！」のみの場合
      return Center(
        child: Text(
          '🙋',
          style: TextStyle(
            fontSize: iconSize,
          ),
        ),
      );
    } else {
      // 「考え中！」のみの場合（defaultはこちら）
      return Center(
        child: Text(
          '🤔',
          style: TextStyle(
            fontSize: iconSize,
          ),
        ),
      );
    }
  }
}
