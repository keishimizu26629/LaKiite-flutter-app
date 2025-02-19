import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/schedule/schedule_interaction_notifier.dart';
import 'package:lakiite/application/schedule/schedule_interaction_state.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/presentation/theme/app_theme.dart';
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

  /// 指定された[type]に応じた[IconData]を返します
  ///
  /// [ReactionType]に基づいて適切なアイコンを返します：
  /// - [ReactionType.going]: 参加アイコン
  /// - [ReactionType.thinking]: 検討中アイコン
  /// - その他: デフォルトのリアクションアイコン
  IconData _getReactionIcon(ReactionType? type) {
    switch (type) {
      case ReactionType.going:
        return Icons.person_add;
      case ReactionType.thinking:
        return Icons.psychology;
      default:
        return Icons.add_reaction_outlined;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentController = useTextEditingController();
    final authState = ref.watch(authNotifierProvider);
    final interactions = ref.watch(
      scheduleInteractionNotifierProvider(schedule.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('予定の詳細'),
      ),
      body: SingleChildScrollView(
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
                        content: authState.value?.user?.id == schedule.ownerId
                            ? '自分'
                            : ownerName,
                      );
                    },
                  );
                },
              ),
              const Divider(height: 32),
              _buildReactionsSection(context, interactions),
              const Divider(height: 32),
              _buildCommentsSection(context, interactions),
            ],
          ),
        ),
      ),
      bottomNavigationBar: authState.when(
        data: (state) {
          if (state.status != AuthStatus.authenticated || state.user == null) {
            return const SizedBox.shrink();
          }

          final userReaction = interactions.getUserReaction(state.user!.id);

          return BottomAppBar(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  PopupMenuButton<ReactionType>(
                    icon: Icon(
                      _getReactionIcon(userReaction?.type),
                      color:
                          userReaction != null ? AppTheme.primaryColor : null,
                    ),
                    onSelected: (ReactionType type) {
                      ref
                          .read(scheduleInteractionNotifierProvider(schedule.id)
                              .notifier)
                          .toggleReaction(state.user!.id, type);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: ReactionType.going,
                        child: Row(
                          children: [
                            const Text('🙋 '),
                            const Text('行きます！'),
                            const Spacer(),
                            if (userReaction?.type == ReactionType.going)
                              const Icon(Icons.check,
                                  color: AppTheme.primaryColor),
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
                            if (userReaction?.type == ReactionType.thinking)
                              const Icon(Icons.check,
                                  color: AppTheme.primaryColor),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: 'コメントを追加...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        ref
                            .read(
                                scheduleInteractionNotifierProvider(schedule.id)
                                    .notifier)
                            .addComment(state.user!.id, commentController.text);
                        commentController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
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

  /// リアクションセクションを構築する[Widget]を返します
  ///
  /// [interactions]から現在のリアクション状態を取得し、
  /// リアクションの種類ごとの集計を表示します。
  Widget _buildReactionsSection(
    BuildContext context,
    ScheduleInteractionState interactions,
  ) {
    final reactionCounts = interactions.reactionCounts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'リアクション ${interactions.reactions.length}件',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (interactions.reactions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            children: [
              _buildReactionCount(
                emoji: '🙋',
                label: '行きます！',
                count: reactionCounts[ReactionType.going] ?? 0,
              ),
              _buildReactionCount(
                emoji: '🤔',
                label: '考え中！',
                count: reactionCounts[ReactionType.thinking] ?? 0,
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// リアクションのカウントを表示する[Widget]を返します
  ///
  /// [emoji]、[label]、[count]を受け取り、リアクションの
  /// 種類ごとの集計を表示します。[count]が0の場合は何も表示しません。
  Widget _buildReactionCount({
    required String emoji,
    required String label,
    required int count,
  }) {
    if (count == 0) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 4),
        Text('$count', style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.comment, size: 20),
            const SizedBox(width: 8),
            Text(
              'コメント ${interactions.commentCount}件',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...interactions.comments.map((comment) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (comment.userPhotoUrl != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(comment.userPhotoUrl!),
                          radius: 16,
                        )
                      else
                        const CircleAvatar(
                          child: Icon(Icons.person),
                          radius: 16,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.userDisplayName ?? 'ユーザー',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormat('yyyy/MM/dd HH:mm')
                                  .format(comment.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(comment.content),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
