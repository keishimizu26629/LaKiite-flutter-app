import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/calendar/edit_schedule_page.dart';
import 'package:lakiite/presentation/calendar/schedule_detail_page.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/application/schedule/schedule_interaction_notifier.dart';
import 'package:lakiite/presentation/widgets/reaction_icon_widget.dart';

/// 予定タイルを表示するウィジェット
///
/// カレンダー、タイムライン、プロフィールなど様々な箇所で使用される
/// 予定情報を表示するためのカードUIです。表示内容や見た目をカスタマイズできます。
///
/// 予定の詳細情報（タイトル、説明、日時、場所、作成者）とリアクション・コメント情報を表示します。
/// また、オプションで編集ボタンを表示したり、タイムラインビューでの特別なスタイルを適用できます。
class ScheduleTile extends ConsumerWidget {
  /// コンストラクタ
  ///
  /// [schedule] 表示する予定データ
  /// [currentUserId] 現在のユーザーID
  /// [showOwner] 作成者情報を表示するかどうか（デフォルト: true）
  /// [showEditButton] 編集ボタンを表示するかどうか（デフォルト: false）
  /// [showDeleteButton] 削除ボタンを表示するかどうか（デフォルト: false）
  /// [isTimelineView] タイムラインビューとして表示するかどうか（デフォルト: false）
  /// [showDivider] 区切り線を表示するかどうか（デフォルト: false）
  /// [onEditPressed] 編集ボタンがタップされた時のコールバック
  /// [onDeletePressed] 削除ボタンがタップされた時のコールバック
  /// [onReactionTap] リアクション部分がタップされた時のコールバック
  /// [margin] カードのマージン
  const ScheduleTile({
    super.key,
    required this.schedule,
    required this.currentUserId,
    this.showOwner = true,
    this.showEditButton = false,
    this.showDeleteButton = false,
    this.isTimelineView = false,
    this.showDivider = false,
    this.onEditPressed,
    this.onDeletePressed,
    this.onReactionTap,
    this.margin,
  });

  /// 表示する予定のデータ
  final Schedule schedule;

  /// 現在のユーザーID
  final String currentUserId;

  /// 作成者情報を表示するかどうか
  final bool showOwner;

  /// 編集ボタンを表示するかどうか（自分の予定の場合のみ有効）
  final bool showEditButton;

  /// 削除ボタンを表示するかどうか（自分の予定の場合のみ有効）
  final bool showDeleteButton;

  /// タイムラインビューとして表示するかどうか（スタイルに影響）
  final bool isTimelineView;

  /// 区切り線を表示するかどうか
  final bool showDivider;

  /// 編集ボタンがタップされた時のコールバック
  final VoidCallback? onEditPressed;

  /// 削除ボタンがタップされた時のコールバック
  final VoidCallback? onDeletePressed;

  /// リアクション部分がタップされた時のコールバック
  final VoidCallback? onReactionTap;

  /// カードのマージン
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwnSchedule = schedule.ownerId == currentUserId;

    return Card(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isTimelineView && !isOwnSchedule ? 0 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isTimelineView && !isOwnSchedule
            ? BorderSide.none
            : BorderSide(
                color: isTimelineView
                    ? (isOwnSchedule
                        ? Colors.grey[400]!
                        : Theme.of(context).primaryColor.withAlpha(77))
                    : Colors.grey[300]!,
                width: 1,
              ),
      ),
      color: isTimelineView
          ? (isOwnSchedule ? Colors.grey[100] : Colors.white)
          : Colors.grey[50],
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ScheduleDetailPage(schedule: schedule),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      schedule.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isOwnSchedule) ...[
                    if (showEditButton)
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: Colors.grey[600],
                        ),
                        onPressed: onEditPressed ??
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => EditSchedulePage(
                                    schedule: schedule,
                                  ),
                                ),
                              );
                            },
                      ),
                    if (showDeleteButton)
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.grey[600],
                        ),
                        onPressed: onDeletePressed ??
                            () => _showDeleteConfirmDialog(context, ref),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (schedule.description.isNotEmpty) ...[
                Text(
                  schedule.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${DateFormat('yyyy/MM/dd HH:mm').format(schedule.startDateTime)} - '
                      '${DateFormat('yyyy/MM/dd HH:mm').format(schedule.endDateTime)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              if (schedule.location != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        schedule.location!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (showOwner) ...[
                const SizedBox(height: 8),
                FutureBuilder<UserModel?>(
                  future: ref
                      .read(userRepositoryProvider)
                      .getUser(schedule.ownerId),
                  builder: (context, snapshot) {
                    final ownerName = snapshot.hasData
                        ? snapshot.data!.displayName
                        : '読み込み中...';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '作成者: ${isOwnSchedule ? '自分' : ownerName}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (showDivider) const Divider(height: 24),
                      ],
                    );
                  },
                ),
              ],
              // インタラクションセクション（リアクションとコメント）
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // リアクション表示部分
                  if (schedule.reactionCount > 0)
                    // リアクションアイコンをタップすると詳細ページに遷移（または指定されたコールバックを実行）
                    GestureDetector(
                      onTap: onReactionTap ??
                          () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ScheduleDetailPage(schedule: schedule),
                              ),
                            );
                          },
                      child: Consumer(
                        builder: (context, ref, _) {
                          // 予定のインタラクション情報（リアクション、コメント）を取得
                          final interactionState = ref.watch(
                            scheduleInteractionNotifierProvider(schedule.id),
                          );

                          // リアクションアイコンを表示
                          return SizedBox(
                            width: 30,
                            height: 30,
                            child: ReactionIconWidget.fromReactionCounts(
                              interactionState.reactionCounts,
                              isLoading: interactionState.isLoading ||
                                  interactionState.error != null,
                            ),
                          );
                        },
                      ),
                    )
                  else
                    // リアクションがない場合はデフォルトのピープルアイコンを表示
                    Icon(
                      Icons.people,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  const SizedBox(width: 4),
                  // リアクション数を表示
                  Text(
                    '${schedule.reactionCount}',
                    style: TextStyle(
                      color: schedule.reactionCount > 0
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // コメントアイコン
                  Icon(
                    Icons.comment,
                    size: 16,
                    color: Colors.blue[400],
                  ),
                  const SizedBox(width: 4),
                  // コメント数を表示
                  Text(
                    '${schedule.commentCount}',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('予定の削除'),
        content: const Text('この予定を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              // ダイアログを閉じる
              Navigator.of(context).pop();

              // 予定を削除
              ref
                  .read(scheduleNotifierProvider.notifier)
                  .deleteSchedule(schedule.id);

              // 削除完了メッセージ
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('予定を削除しました')),
              );
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
