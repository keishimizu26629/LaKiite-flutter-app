import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/schedule/schedule_interaction_notifier.dart';
import 'package:lakiite/application/schedule/schedule_interaction_state.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/presentation/theme/app_theme.dart';
import 'package:lakiite/presentation/calendar/edit_schedule_page.dart';
import 'package:intl/intl.dart';

/// スケジュールの詳細情報を表示するページ
///
/// [HookConsumerWidget]を継承し、[Riverpod]による状態管理と[Flutter Hooks]を使用して
/// スケジュールの詳細情報、リアクション、コメントを表示・管理します。
class ScheduleDetailPage extends HookConsumerWidget {
  /// [ScheduleDetailPage]のコンストラクタ
  ///
  /// 表示する[schedule]の情報を必須パラメータとして受け取ります。
  const ScheduleDetailPage({
    required this.schedule,
    super.key,
  });

  /// 表示対象の[Schedule]インスタンス
  final Schedule schedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authNotifierProvider);
    final interactions = ref.watch(
      scheduleInteractionNotifierProvider(schedule.id),
    );
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
                            Row(
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    if (interactions.reactions.isNotEmpty)
                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 30,
                                            height: 30,
                                            child: Stack(
                                              children: [
                                                if (interactions.reactionCounts[
                                                            ReactionType
                                                                .thinking] !=
                                                        null &&
                                                    interactions.reactionCounts[
                                                            ReactionType
                                                                .thinking]! >
                                                        0)
                                                  const Positioned(
                                                    right: 2,
                                                    child: Text(
                                                      '🤔',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                  ),
                                                if (interactions.reactionCounts[
                                                            ReactionType
                                                                .going] !=
                                                        null &&
                                                    interactions.reactionCounts[
                                                            ReactionType
                                                                .going]! >
                                                        0)
                                                  Positioned(
                                                    top: -1,
                                                    right: interactions.reactionCounts[
                                                                    ReactionType
                                                                        .thinking] !=
                                                                null &&
                                                            interactions.reactionCounts[
                                                                    ReactionType
                                                                        .thinking]! >
                                                                0
                                                        ? null
                                                        : 2,
                                                    left: interactions.reactionCounts[
                                                                    ReactionType
                                                                        .thinking] !=
                                                                null &&
                                                            interactions.reactionCounts[
                                                                    ReactionType
                                                                        .thinking]! >
                                                                0
                                                        ? -2
                                                        : null,
                                                    child: const Text(
                                                      '🙋',
                                                      style: TextStyle(
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Icon(
                                        Icons.people,
                                        size: 20,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${interactions.reactions.length}',
                                      style: TextStyle(
                                        color: interactions.reactions.isNotEmpty
                                            ? Colors.grey
                                            : Theme.of(context).primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                ),
                                Icon(
                                  Icons.comment,
                                  size: 20,
                                  color: Colors.blue[400],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${interactions.commentCount}',
                                  style: TextStyle(
                                    color: Colors.blue[400],
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
                    const CircleAvatar(
                      child: Icon(Icons.person),
                      radius: 20,
                    ),
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
}
