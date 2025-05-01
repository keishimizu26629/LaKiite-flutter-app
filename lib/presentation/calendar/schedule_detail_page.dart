import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/schedule/schedule_interaction_state.dart';
import 'package:lakiite/application/schedule/schedule_interaction_notifier.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/presentation/theme/app_theme.dart';
import 'package:lakiite/presentation/calendar/edit_schedule_page.dart';
import 'package:lakiite/presentation/widgets/default_user_icon.dart';
import 'package:lakiite/domain/entity/notification.dart' as domain;
import 'package:lakiite/application/notification/notification_notifier.dart';
import 'package:lakiite/presentation/widgets/reaction_icon_widget.dart';

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
    super.key,
  });

  /// 表示対象の[Schedule]インスタンス
  final Schedule schedule;

  /// 通知からの遷移かどうか
  final bool fromNotification;

  /// 遷移元の通知ID（通知からの遷移時のみ）
  final String? notificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authNotifierProvider);
    final interactions = ref.watch(
      scheduleInteractionNotifierProvider(schedule.id),
    );

    // スケジュール詳細ページが開かれたときに関連する通知を既読にする
    useEffect(() {
      // 通知からの遷移情報をログ出力
      developer.log(
          'スケジュール詳細ページが開かれました - fromNotification: $fromNotification, notificationId: ${notificationId ?? "null"}');

      // 通常の既読処理を実行
      _markRelatedNotificationsAsRead(ref);

      // 通知からの遷移の場合、特定の通知を既読にする
      if (fromNotification && notificationId != null) {
        _markSpecificNotificationAsRead(ref, notificationId!);
      }

      return null;
    }, []);

    // ここでリアクションデータをログ出力
    developer.log('スケジュールID: ${schedule.id}');
    developer.log('リアクション数: ${schedule.reactionCount}');
    developer.log('リアクション一覧: ${interactions.reactions.length}件');
    for (var reaction in interactions.reactions) {
      developer.log('リアクション: userId=${reaction.userId}, type=${reaction.type}');
    }

    useFocusNode();

    return Scaffold(
      appBar: AppBar(
        title: const Text('予定の詳細'),
        actions: [
          if (schedule.ownerId ==
              ref.watch(authNotifierProvider).value?.user?.id)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditSchedulePage(
                        schedule: schedule,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoSection(
                      icon: Icons.calendar_today,
                      title: '日時',
                      content:
                          '${DateFormat('yyyy年M月d日（E） HH:mm', 'ja_JP').format(schedule.startDateTime)} - ${DateFormat('HH:mm', 'ja_JP').format(schedule.endDateTime)}',
                    ),
                    if (schedule.location != null)
                      _buildInfoSection(
                        icon: Icons.location_on,
                        title: '場所',
                        content: schedule.location!,
                      ),
                    _buildInfoSection(
                      icon: Icons.description,
                      title: '説明',
                      content: schedule.description,
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final authState = ref.watch(authNotifierProvider);
                        return FutureBuilder<UserModel?>(
                          future: ref
                              .read(userRepositoryProvider)
                              .getUser(schedule.ownerId),
                          builder: (context, snapshot) {
                            final ownerName = snapshot.hasData
                                ? snapshot.data!.displayName
                                : '読み込み中...';
                            return _buildInfoSection(
                              icon: Icons.person,
                              title: '作成者',
                              content:
                                  authState.value?.user?.id == schedule.ownerId
                                      ? '自分'
                                      : ownerName,
                            );
                          },
                        );
                      },
                    ),
                    // リアクションボタンとコメントボタン
                    Consumer(
                      builder: (context, ref, _) {
                        final authState = ref.watch(authNotifierProvider);
                        if (authState.value?.status !=
                                AuthStatus.authenticated ||
                            authState.value?.user == null) {
                          return const SizedBox.shrink();
                        }

                        final userReaction = interactions
                            .getUserReaction(authState.value!.user!.id);

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        _showReactionUsers(context, ref),
                                    child: Row(
                                      children: [
                                        if (schedule.reactionCount > 0)
                                          SizedBox(
                                            width: 30,
                                            height: 30,
                                            child: ReactionIconWidget(
                                              hasGoing: interactions.reactions
                                                  .any((r) =>
                                                      r.type ==
                                                      ReactionType.going),
                                              hasThinking: interactions
                                                  .reactions
                                                  .any((r) =>
                                                      r.type ==
                                                      ReactionType.thinking),
                                            ),
                                          )
                                        else
                                          Icon(
                                            Icons.people,
                                            size: 16,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${schedule.reactionCount}',
                                          style: TextStyle(
                                            color: schedule.reactionCount > 0
                                                ? Colors.grey
                                                : Theme.of(context)
                                                    .primaryColor,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
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
                                    '${schedule.commentCount}',
                                    style: TextStyle(
                                      color: Colors.blue[400],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: PopupMenuButton<ReactionType>(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          if (userReaction != null)
                                            Text(
                                              userReaction.type ==
                                                      ReactionType.going
                                                  ? '🙋'
                                                  : '🤔',
                                              style: const TextStyle(
                                                fontSize: 20,
                                              ),
                                            )
                                          else
                                            const Icon(
                                              Icons.add_reaction_outlined,
                                              color: Colors.grey,
                                              size: 20,
                                            ),
                                          const SizedBox(width: 8),
                                          Text(
                                            userReaction != null
                                                ? (userReaction.type ==
                                                        ReactionType.going
                                                    ? '行きます！'
                                                    : '考え中！')
                                                : 'リアクション',
                                            style: TextStyle(
                                              color: userReaction != null
                                                  ? Theme.of(context)
                                                      .primaryColor
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
                                                      schedule.id)
                                                  .notifier)
                                          .toggleReaction(
                                              authState.value!.user!.id, type);
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: ReactionType.going,
                                        child: Row(
                                          children: [
                                            const Text('🙋 '),
                                            const Text('行きます！'),
                                            const Spacer(),
                                            if (userReaction?.type ==
                                                ReactionType.going)
                                              const Text('✓',
                                                  style: TextStyle(
                                                      color: AppTheme
                                                          .primaryColor)),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: ReactionType.thinking,
                                        child: Row(
                                          children: [
                                            const Text('🤔 '),
                                            const Text('考え中！'),
                                            const Spacer(),
                                            if (userReaction?.type ==
                                                ReactionType.thinking)
                                              const Text('✓',
                                                  style: TextStyle(
                                                      color: AppTheme
                                                          .primaryColor)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      _showCommentDialog(context, ref,
                                          authState.value!.user!.id);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.comment_outlined,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'コメント',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                    _buildCommentsSection(context, interactions),
                    // キーボードが表示された時の余白
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }

  /// コメント入力ダイアログを表示します
  ///
  /// ユーザーがコメントを入力するためのモーダルボトムシートを表示します。
  /// 送信ボタンが押されると、入力されたコメントをスケジュールに追加します。
  ///
  /// [context] ダイアログを表示するためのビルドコンテキスト
  /// [ref] Riverpodの参照
  /// [userId] コメントを投稿するユーザーのID
  void _showCommentDialog(BuildContext context, WidgetRef ref, String userId) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'コメントを追加',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: 'コメントを入力...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        ref
                            .read(
                                scheduleInteractionNotifierProvider(schedule.id)
                                    .notifier)
                            .addComment(userId, commentController.text);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('送信'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    for (var reaction in reactions) {
      developer
          .log('取得したリアクション: userId=${reaction.userId}, type=${reaction.type}');
    }

    if (!context.mounted) return;

    // リアクションが存在しない場合は通知を表示
    if (reactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('リアクションがありません')),
      );
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                reactions.map((reaction) => ref
                    .read(userRepositoryProvider)
                    .getUser(reaction.userId)
                    .then((user) => user!)),
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
                      developer.log(
                          '表示するユーザー: ${user.displayName}, リアクション: ${reaction.type}');
                      return ListTile(
                        leading: Stack(
                          children: [
                            const DefaultUserIcon(),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Text(
                                reaction.type == ReactionType.going
                                    ? '🙋'
                                    : '🤔',
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

  /// 情報セクションを構築する[Widget]を返します
  ///
  /// [icon]、[title]、[content]を受け取り、一貫したレイアウトで
  /// 情報を表示するセクションを構築します。
  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// コメントセクションを構築する[Widget]を返します
  ///
  /// [interactions]から現在のコメント一覧を取得し、
  /// ユーザー情報、投稿日時、コメント本文を表示します。
  Widget _buildCommentsSection(
    BuildContext context,
    ScheduleInteractionState interactions,
  ) {
    // コメントを日時の昇順でソート
    final sortedComments = [...interactions.comments]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...sortedComments.map((comment) {
          return Padding(
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
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comment.userDisplayName ?? 'ユーザー',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                comment.content,
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4),
                          child: Text(
                            DateFormat('M月d日 HH:mm').format(comment.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
        developer
            .log('通知: id=${notification.id}, type=${notification.type.name}, '
                'isRead=${notification.isRead}, '
                'relatedItemId=${notification.relatedItemId ?? "null"}, '
                'sendUserId=${notification.sendUserId}, '
                'receiveUserId=${notification.receiveUserId}, '
                'status=${notification.status.name}, '
                'createdAt=${notification.createdAt}');
      }

      // このスケジュールに関連する未読のリアクション・コメント通知をフィルタリング
      final unreadRelatedNotifications = notifications
          .where((notification) =>
              !notification.isRead &&
              (notification.type == domain.NotificationType.reaction ||
                  notification.type == domain.NotificationType.comment) &&
              notification.relatedItemId == schedule.id)
          .toList();

      developer.log('未読の関連通知数: ${unreadRelatedNotifications.length}件');
      developer.log('現在のスケジュールID: ${schedule.id}');

      // フィルタリングされた通知の詳細ログ
      for (final notification in unreadRelatedNotifications) {
        developer
            .log('関連通知: id=${notification.id}, type=${notification.type.name}, '
                'relatedItemId=${notification.relatedItemId}');
      }

      // 各通知を既読にする（非同期で実行、結果を待たない）
      final notifier = ref.read(notificationNotifierProvider.notifier);

      for (final notification in unreadRelatedNotifications) {
        developer.log(
            '通知を既読にします: ${notification.id}, type=${notification.type.name}');
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
      WidgetRef ref, String notificationId) async {
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
}
