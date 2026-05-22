import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/application/schedule/schedule_interaction_state.dart';
import 'package:lakiite/application/schedule/schedule_interaction_notifier.dart';
import 'package:lakiite/application/schedule/schedule_notifier.dart';
import 'package:lakiite/presentation/theme/app_theme.dart';
import 'package:lakiite/presentation/calendar/edit_schedule_page.dart';
import 'package:lakiite/presentation/widgets/default_user_icon.dart';
import 'package:lakiite/domain/entity/notification.dart' as domain;
import 'package:lakiite/application/notification/notification_notifier.dart';
import 'package:lakiite/presentation/widgets/reaction_icon_widget.dart';
import 'package:lakiite/presentation/widgets/reaction_type_view_extension.dart';

/// スケジュールの詳細情報を表示するページ
///
/// [HookConsumerWidget]を継承し、[Riverpod]による状態管理と[Flutter Hooks]を使用して
/// スケジュールの詳細情報、リアクション、コメントを表示・管理します。
class ScheduleDetailPage extends HookConsumerWidget {
  /// [ScheduleDetailPage]のコンストラクタ
  ///
  /// 表示する[schedule]の情報を必須パラメータとして受け取ります。
  /// [fromNotification]は通知からの遷移かどうかを示します。
  /// [notificationId]は遷移元の通知IDを指定します（通知からの遷移時のみ）。
  const ScheduleDetailPage({
    required this.schedule,
    this.fromNotification = false,
    this.notificationId,
    this.notificationType,
    this.interactionId,
    super.key,
  });

  /// 表示対象の[Schedule]インスタンス
  final Schedule schedule;

  /// 通知からの遷移かどうか
  final bool fromNotification;

  /// 遷移元の通知ID（通知からの遷移時のみ）
  final String? notificationId;

  /// 遷移元の通知タイプ（通知からの遷移時のみ）
  final domain.NotificationType? notificationType;

  /// 遷移元通知が指すリアクションまたはコメントID
  final String? interactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authNotifierProvider);
    final interactions = ref.watch(
      scheduleInteractionNotifierProvider(schedule.id),
    );
    final scrollController = useScrollController();
    final reactionSectionKey = useMemoized(GlobalKey.new);
    final commentSectionKey = useMemoized(GlobalKey.new);
    final targetCommentKey = useMemoized(GlobalKey.new);
    final didScrollToNotificationTarget = useRef(false);

    // スケジュールのリアルタイム監視を行うStreamProviderを作成
    final scheduleStreamProvider = StreamProvider<Schedule?>((ref) {
      return ref
          .read(scheduleNotifierProvider.notifier)
          .watchSchedule(schedule.id);
    });

    // 監視中のスケジュール情報
    final watchedScheduleAsync = ref.watch(scheduleStreamProvider);

    // 現在表示すべきスケジュール情報を取得（最新のデータが取得できたらそれを使用、そうでなければ初期データ）
    final currentSchedule = watchedScheduleAsync.when(
      data: (updatedSchedule) => updatedSchedule ?? schedule,
      loading: () => schedule,
      error: (_, __) => schedule,
    );

    // コメント入力用のテキストコントローラー
    final commentController = useTextEditingController();

    // スケジュール詳細ページが開かれたときに関連する通知を既読にする
    useEffect(() {
      // 通知からの遷移情報をログ出力
      developer.log(
        'スケジュール詳細ページが開かれました - fromNotification: $fromNotification, notificationId: ${notificationId ?? "null"}',
      );

      // 通常の既読処理を実行
      _markRelatedNotificationsAsRead(ref);

      // 通知からの遷移の場合、特定の通知を既読にする
      if (fromNotification && notificationId != null) {
        _markSpecificNotificationAsRead(ref, notificationId!);
      }

      return null;
    }, []);

    useEffect(
      () {
        if (!fromNotification || didScrollToNotificationTarget.value) {
          return null;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted || didScrollToNotificationTarget.value) {
            return;
          }

          GlobalKey? targetKey;
          switch (notificationType) {
            case domain.NotificationType.reaction:
              targetKey = reactionSectionKey;
              break;
            case domain.NotificationType.comment:
              final hasTargetComment = interactionId != null &&
                  interactions.comments.any(
                    (comment) => comment.id == interactionId,
                  );
              targetKey =
                  hasTargetComment ? targetCommentKey : commentSectionKey;
              break;
            case domain.NotificationType.friend:
            case domain.NotificationType.groupInvitation:
            case null:
              targetKey = null;
              break;
          }

          final targetContext = targetKey?.currentContext;
          if (targetContext == null) {
            return;
          }

          didScrollToNotificationTarget.value = true;
          Scrollable.ensureVisible(
            targetContext,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: 0.08,
          );
        });

        return null;
      },
      [
        fromNotification,
        notificationType,
        interactionId,
        interactions.comments.length,
        interactions.reactions.length,
      ],
    );

    // ここでリアクションデータをログ出力
    // developer.log('スケジュールID: ${currentSchedule.id}');
    // developer.log('リアクション数: ${currentSchedule.reactionCount}');
    // developer.log('リアクション一覧: ${interactions.reactions.length}件');
    // for (var reaction in interactions.reactions) {
    //   developer.log('リアクション: userId=${reaction.userId}, type=${reaction.type}');
    // }

    return Scaffold(
      appBar: AppBar(
        title: const Text('予定の詳細'),
        actions: [
          if (currentSchedule.ownerId ==
              ref.watch(authNotifierProvider).value?.user?.id) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          EditSchedulePage(schedule: currentSchedule),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () =>
                    _showDeleteConfirmDialog(context, ref, currentSchedule),
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // スケジュール情報ヘッダー
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // スケジュールのタイトル
                          Text(
                            currentSchedule.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 日時情報
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.indigo,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatDateTimeRange(
                                    currentSchedule.startDateTime,
                                    currentSchedule.endDateTime,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 場所情報（あれば表示）
                          if (currentSchedule.location != null &&
                              currentSchedule.location!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.redAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      currentSchedule.location!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          // 作成者情報
                          Row(
                            children: [
                              if (currentSchedule.ownerPhotoUrl != null)
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage: NetworkImage(
                                    currentSchedule.ownerPhotoUrl!,
                                  ),
                                )
                              else
                                const DefaultUserIcon(size: 32),
                              const SizedBox(width: 8),
                              Text(
                                currentSchedule.ownerDisplayName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // インタラクション情報（リアクション数・コメント数）
                          Container(
                            key: reactionSectionKey,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: notificationType ==
                                      domain.NotificationType.reaction
                                  ? Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.08)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                              border: notificationType ==
                                      domain.NotificationType.reaction
                                  ? Border.all(
                                      color: Theme.of(context).primaryColor,
                                      width: 1.5,
                                    )
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => _showReactionUsers(context, ref),
                                  child: Row(
                                    children: [
                                      if (interactions.reactions.isNotEmpty)
                                        SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: ReactionIconWidget(
                                            hasGoing:
                                                interactions.reactions.any(
                                              (r) =>
                                                  r.type == ReactionType.going,
                                            ),
                                            hasThinking:
                                                interactions.reactions.any(
                                              (r) =>
                                                  r.type ==
                                                  ReactionType.thinking,
                                            ),
                                          ),
                                        )
                                      else
                                        Icon(
                                          Icons.people,
                                          size: 16,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${interactions.reactions.length}',
                                        style: TextStyle(
                                          color: interactions
                                                  .reactions.isNotEmpty
                                              ? Colors.grey
                                              : Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Icon(
                                  Icons.comment,
                                  size: 16,
                                  color: Colors.blue[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${interactions.comments.length}',
                                  style: TextStyle(
                                    color: Colors.blue[400],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // スケジュールの説明
                          Text(
                            currentSchedule.description,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          // リアクションボタン
                          ref.watch(authNotifierProvider).when(
                                data: (authState) {
                                  if (authState.user == null) {
                                    return Container(); // 未ログイン時は表示しない
                                  }

                                  // 現在のユーザーのリアクションを取得
                                  final userReaction = interactions
                                      .getUserReaction(authState.user!.id);

                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      PopupMenuButton<ReactionType>(
                                        elevation: 3.0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[100],
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.add_reaction,
                                                size: 20,
                                                color: userReaction != null
                                                    ? Theme.of(
                                                        context,
                                                      ).primaryColor
                                                    : Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                userReaction != null
                                                    ? userReaction.type.label
                                                    : 'リアクション',
                                                style: TextStyle(
                                                  color: userReaction != null
                                                      ? Theme.of(
                                                          context,
                                                        ).primaryColor
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        onSelected: (ReactionType type) {
                                          ref
                                              .read(
                                                scheduleInteractionNotifierProvider(
                                                  currentSchedule.id,
                                                ).notifier,
                                              )
                                              .toggleReaction(
                                                authState.user!.id,
                                                type,
                                              );
                                        },
                                        itemBuilder: (context) => [
                                          PopupMenuItem(
                                            value: ReactionType.going,
                                            child: Row(
                                              children: [
                                                const Text('🙋 '),
                                                Text(ReactionType.going.label),
                                                const Spacer(),
                                                if (userReaction?.type ==
                                                    ReactionType.going)
                                                  const Text(
                                                    '✓',
                                                    style: TextStyle(
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuItem(
                                            value: ReactionType.thinking,
                                            child: Row(
                                              children: [
                                                const Text('🤔 '),
                                                Text(ReactionType
                                                    .thinking.label),
                                                const Spacer(),
                                                if (userReaction?.type ==
                                                    ReactionType.thinking)
                                                  const Text(
                                                    '✓',
                                                    style: TextStyle(
                                                      color:
                                                          AppTheme.primaryColor,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (e, st) => Text('エラー: $e'),
                              ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // コメント一覧
                    if (interactions.comments.isNotEmpty)
                      Padding(
                        key: commentSectionKey,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'コメント',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCommentsSection(
                              context,
                              interactions,
                              ref,
                              targetCommentKey,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // コメント入力部分
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: 'コメントを追加...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        // コメント送信処理
                        final authState = ref.read(authNotifierProvider).value;
                        if (authState?.user != null &&
                            commentController.text.isNotEmpty) {
                          ref
                              .read(
                                scheduleInteractionNotifierProvider(
                                  currentSchedule.id,
                                ).notifier,
                              )
                              .addComment(
                                authState!.user!.id,
                                commentController.text,
                              );
                          commentController.clear();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// リアクションしたユーザーの一覧を表示します
  ///
  /// スケジュールにリアクションしたユーザーの一覧をモーダルボトムシートで表示します。
  /// リアクションがない場合はスナックバーで通知します。
  ///
  /// [context] ダイアログを表示するためのビルドコンテキスト
  /// [ref] Riverpodの参照
  ///
  /// 返り値: 非同期処理の完了を表す[Future]
  Future<void> _showReactionUsers(BuildContext context, WidgetRef ref) async {
    final reactions = await ref
        .read(reactionRepositoryProvider)
        .getReactionsForSchedule(schedule.id);

    // リポジトリから取得したリアクションデータをログ出力
    developer.log('リポジトリから取得したリアクション: ${reactions.length}件');
    for (final reaction in reactions) {
      developer.log(
        '取得したリアクション: userId=${reaction.userId}, type=${reaction.type}',
      );
    }

    if (!context.mounted) return;

    // リアクションが存在しない場合は通知を表示
    if (reactions.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('リアクションがありません')));
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'リアクションした人',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<UserModel>>(
              future: Future.wait(
                reactions.map(
                  (reaction) => ref
                      .read(userRepositoryProvider)
                      .getUser(reaction.userId)
                      .then((user) => user!),
                ),
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('エラー: ${snapshot.error}'));
                }

                final users = snapshot.data!;
                developer.log('リアクションユーザー: ${users.length}人');
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final reaction = reactions[index];
                      // 追加のデバッグログ
                      developer.log('リアクションオブジェクト: $reaction');
                      developer.log(
                        'リアクションタイプ: ${reaction.type} (${reaction.type.runtimeType})',
                      );

                      return ListTile(
                        leading: Stack(
                          children: [
                            user.iconUrl != null
                                ? CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      user.iconUrl!,
                                    ),
                                  )
                                : const DefaultUserIcon(),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Text(
                                reaction.type.emoji,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        title: Text(user.displayName),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 日時の範囲をフォーマットするヘルパーメソッド
  String _formatDateTimeRange(DateTime start, DateTime end) {
    final dateFormat = DateFormat('yyyy年M月d日（E）', 'ja_JP');
    final timeFormat = DateFormat('HH:mm', 'ja_JP');

    // 同日の場合は日付を1つだけ表示
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${dateFormat.format(start)} ${timeFormat.format(start)} - ${timeFormat.format(end)}';
    } else {
      // 日付が異なる場合は両方の日付を表示
      return '${dateFormat.format(start)} ${timeFormat.format(start)} - ${dateFormat.format(end)} ${timeFormat.format(end)}';
    }
  }

  /// スケジュールに関連する通知を既読にします
  ///
  /// スケジュールに関連するリアクションやコメントの未読通知を既読状態に更新します。
  /// スケジュールの所有者が現在のユーザーでない場合は何もしません。
  ///
  /// [ref] Riverpodの参照
  ///
  /// 返り値: 非同期処理の完了を表す[Future]
  Future<void> _markRelatedNotificationsAsRead(WidgetRef ref) async {
    try {
      // 現在のユーザーを取得
      final authState = ref.read(authNotifierProvider).value;
      if (authState?.user == null) return;

      final userId = authState!.user!.id;

      // このスケジュールの所有者が自分でなければ何もしない
      if (schedule.ownerId != userId) return;

      developer.log('スケジュール詳細ページでの通知既読処理を開始: scheduleId=${schedule.id}');

      // 受信した通知を取得
      final notificationsAsync = ref.read(receivedNotificationsProvider);

      if (!notificationsAsync.hasValue) {
        developer.log('通知データがまだ読み込まれていません');
        return;
      }

      final notifications = notificationsAsync.value ?? [];

      developer.log('受信した通知数: ${notifications.length}件');

      // 全通知の詳細をログ出力
      for (final notification in notifications) {
        developer.log(
          '通知: id=${notification.id}, type=${notification.type.name}, '
          'isRead=${notification.isRead}, '
          'relatedItemId=${notification.relatedItemId ?? "null"}, '
          'sendUserId=${notification.sendUserId}, '
          'receiveUserId=${notification.receiveUserId}, '
          'status=${notification.status.name}, '
          'createdAt=${notification.createdAt}',
        );
      }

      // このスケジュールに関連する未読のリアクション・コメント通知をフィルタリング
      final unreadRelatedNotifications = notifications
          .where(
            (notification) =>
                !notification.isRead &&
                (notification.type == domain.NotificationType.reaction ||
                    notification.type == domain.NotificationType.comment) &&
                notification.relatedItemId == schedule.id,
          )
          .toList();

      developer.log('未読の関連通知数: ${unreadRelatedNotifications.length}件');
      developer.log('現在のスケジュールID: ${schedule.id}');

      // フィルタリングされた通知の詳細ログ
      for (final notification in unreadRelatedNotifications) {
        developer.log(
          '関連通知: id=${notification.id}, type=${notification.type.name}, '
          'relatedItemId=${notification.relatedItemId}',
        );
      }

      // 各通知を既読にする（非同期で実行、結果を待たない）
      final notifier = ref.read(notificationNotifierProvider.notifier);

      for (final notification in unreadRelatedNotifications) {
        developer.log(
          '通知を既読にします: ${notification.id}, type=${notification.type.name}',
        );
        try {
          await notifier.markAsRead(notification.id);
          developer.log('通知を既読にしました: ${notification.id}');
        } catch (e) {
          developer.log('通知の既読処理でエラーが発生: $e');
          // エラーは無視し、処理を継続
        }
      }

      developer.log('スケジュール詳細ページでの通知既読処理が完了しました');
    } catch (e) {
      developer.log('スケジュール詳細ページでの通知既読処理中にエラーが発生しました: $e');
    }
  }

  /// 特定の通知を既読にします
  ///
  /// 通知ページからの遷移時に、遷移元の通知を既読状態に更新します。
  ///
  /// [ref] Riverpodの参照
  /// [notificationId] 既読にする通知のID
  ///
  /// 返り値: 非同期処理の完了を表す[Future]
  Future<void> _markSpecificNotificationAsRead(
    WidgetRef ref,
    String notificationId,
  ) async {
    try {
      developer.log('特定の通知を既読にします: notificationId=$notificationId');

      // 特定の通知IDが指定されていることを確認
      if (notificationId.isEmpty) {
        developer.log('通知IDが空です');
        return;
      }

      final notifier = ref.read(notificationNotifierProvider.notifier);

      // 既読処理を確実に実行（非同期で待機）
      try {
        await notifier.markAsRead(notificationId);
        developer.log('特定の通知を既読にしました: notificationId=$notificationId');
      } catch (e) {
        developer.log('特定の通知を既読処理でエラー発生: $e');
      }
    } catch (e) {
      developer.log('特定の通知を既読にする処理の初期化でエラーが発生しました: $e');
    }
  }

  /// コメントセクションを構築する[Widget]を返します
  ///
  /// [interactions]から現在のコメント一覧を取得し、
  /// ユーザー情報、投稿日時、コメント本文を表示します。
  Widget _buildCommentsSection(
    BuildContext context,
    ScheduleInteractionState interactions,
    WidgetRef ref,
    GlobalKey targetCommentKey,
  ) {
    // 現在のユーザーIDを取得
    final currentUserId = ref.read(authNotifierProvider).value?.user?.id;

    // コメントを日時の昇順でソート
    final sortedComments = [...interactions.comments]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sortedComments.map((comment) {
          // 自分のコメントかどうかをチェック
          final isMyComment =
              currentUserId != null && comment.userId == currentUserId;
          final isTargetComment = fromNotification &&
              notificationType == domain.NotificationType.comment &&
              interactionId == comment.id;

          return Padding(
            key: isTargetComment ? targetCommentKey : null,
            padding: const EdgeInsets.only(bottom: 16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (comment.userPhotoUrl != null)
                    CircleAvatar(
                      backgroundImage: NetworkImage(comment.userPhotoUrl!),
                      radius: 20,
                    )
                  else
                    const DefaultUserIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isTargetComment
                                ? Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.08)
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: isTargetComment
                                ? Border.all(
                                    color: Theme.of(context).primaryColor,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    comment.userDisplayName ?? 'ユーザー',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  // 自分のコメントの場合に編集・削除メニューを表示
                                  if (isMyComment)
                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      padding: EdgeInsets.zero,
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, size: 16),
                                              SizedBox(width: 8),
                                              Text('編集'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete,
                                                size: 16,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                '削除',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        // refを渡す
                                        final currentRef = ref;
                                        if (value == 'edit') {
                                          _editComment(
                                            context,
                                            currentRef,
                                            comment,
                                          );
                                        } else if (value == 'delete') {
                                          _deleteComment(
                                            context,
                                            currentRef,
                                            comment,
                                          );
                                        }
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.content,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4),
                          child: Text(
                            comment.isEdited
                                ? '${DateFormat('M月d日 HH:mm').format(comment.createdAt)} (編集済み)'
                                : DateFormat(
                                    'M月d日 HH:mm',
                                  ).format(comment.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // コメント削除の確認ダイアログを表示
  void _deleteComment(
    BuildContext context,
    WidgetRef ref,
    ScheduleComment comment,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コメントの削除'),
        content: const Text('このコメントを削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              // ダイアログを閉じる
              Navigator.of(context).pop();

              // コメントを削除
              ref
                  .read(
                    scheduleInteractionNotifierProvider(schedule.id).notifier,
                  )
                  .deleteComment(comment.id);

              // 削除完了メッセージ
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('コメントを削除しました')));
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // コメント編集ダイアログを表示
  void _editComment(
    BuildContext context,
    WidgetRef ref,
    ScheduleComment comment,
  ) {
    // 編集用テキストコントローラー
    final editController = TextEditingController(text: comment.content);

    developer.log(
      'コメント編集開始: id=${comment.id}, userId=${comment.userId}, currentAuthUser=${ref.read(authNotifierProvider).value?.user?.id}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('コメントの編集'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'コメントを入力...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              // 空のコメントは無視
              if (editController.text.trim().isEmpty) {
                return;
              }

              developer.log(
                'コメント編集を実行: commentId=${comment.id}, content=${editController.text}',
              );

              // ダイアログを閉じる
              Navigator.of(context).pop();

              // 編集処理中を示すスナックバーを表示
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('コメントを更新中...'),
                  duration: Duration(seconds: 2),
                ),
              );

              try {
                // リクエスト情報をログ出力
                developer.log(
                  'コメント更新リクエスト: scheduleId=${schedule.id}, commentId=${comment.id}, commentUserId=${comment.userId}',
                );
                developer.log(
                  '認証状態: ${ref.read(authNotifierProvider).value?.user != null ? "ログイン中" : "未ログイン"}',
                );
                if (ref.read(authNotifierProvider).value?.user != null) {
                  developer.log(
                    '現在のユーザーID: ${ref.read(authNotifierProvider).value!.user!.id}',
                  );
                }

                // コメントを更新
                ref
                    .read(
                      scheduleInteractionNotifierProvider(schedule.id).notifier,
                    )
                    .updateComment(comment.id, editController.text)
                    .then((_) {
                  developer.log('コメント更新成功: ${comment.id}');
                  // 編集完了メッセージ
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('コメントを編集しました')),
                  );
                }).catchError((error) {
                  developer.log('コメント更新エラー詳細: $error', error: error);
                  // スタックトレースも記録
                  developer.log('スタックトレース: ${StackTrace.current}');

                  // より詳細なエラーメッセージを表示
                  var errorMsg = 'コメント更新に失敗しました';
                  if (error.toString().contains('permission-denied')) {
                    errorMsg += ': 権限エラー - Firebaseルールによりアクセスが拒否されました';
                  } else if (error.toString().contains('content')) {
                    errorMsg += ': フィールド名の不一致（contentフィールド）';
                  } else if (error.toString().contains('text')) {
                    errorMsg += ': フィールド名の不一致（textフィールド）';
                  }

                  // エラー表示
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('エラー: $errorMsg'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                });
              } catch (e) {
                developer.log('コメント更新中に例外が発生: $e', error: e);
                developer.log('スタックトレース: ${StackTrace.current}');
                // エラー表示
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('エラー: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    Schedule schedule,
  ) {
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

              // 削除完了メッセージを表示してページを閉じる
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('予定を削除しました')));

              // 予定詳細ページを閉じる
              Navigator.of(context).pop();
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
