import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import '../../application/schedule/schedule_notifier.dart';
import '../../application/auth/auth_notifier.dart';
import '../../domain/entity/schedule.dart';
import '../../domain/entity/schedule_reaction.dart';
import '../../application/schedule/schedule_interaction_notifier.dart';
import '../../application/schedule/schedule_interaction_state.dart';
import '../../utils/logger.dart';

class ScheduleDetailPage extends HookConsumerWidget {
  final String scheduleId;

  const ScheduleDetailPage({
    super.key,
    required this.scheduleId,
  });

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ウィジェットのキーを使用して強制的に再レンダリングを制御
    final reactionKey = useMemoized(() => GlobalKey(), [scheduleId]);
    final commentKey = useMemoized(() => GlobalKey(), [scheduleId]);

    // RefreshIndicatorのキー
    final refreshKey =
        useMemoized(() => GlobalKey<RefreshIndicatorState>(), []);

    // スクロールコントローラー
    final scrollController = useScrollController();

    // スケジュールの監視
    final scheduleAsync = ref.watch(scheduleProvider(scheduleId));
    final currentUserId = ref.watch(currentUserIdProvider);

    // インタラクション状態の監視
    final interactionState =
        ref.watch(scheduleInteractionNotifierProvider(scheduleId));

    // リアクションとコメントの変更を検知するためのuseEffect
    useEffect(() {
      // 状態が変わったときにキーを更新して強制的に再レンダリング
      final subscription = Future.microtask(() {});
      return () => subscription;
    }, [interactionState.reactions.length, interactionState.comments.length]);

    // 手動リフレッシュの処理
    Future<void> handleRefresh() async {
      AppLogger.debug('ScheduleDetailPage: リフレッシュを開始');

      // StreamProviderを再購読して状態を取り直す
      ref.invalidate(scheduleProvider(scheduleId));
      // インタラクション情報も明示的に更新
      ref.invalidate(scheduleInteractionNotifierProvider(scheduleId));

      // 完了を待つ（確実にリフレッシュを完了させるため）
      await Future.wait([
        ref.refresh(scheduleProvider(scheduleId).future),
        Future.delayed(const Duration(milliseconds: 500))
      ]);

      AppLogger.debug('ScheduleDetailPage: リフレッシュが完了');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('予定の詳細'),
        actions: [
          scheduleAsync.when(
            data: (schedule) {
              if (schedule != null && schedule.ownerId == currentUserId) {
                return IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    context.push('/schedule/edit/${schedule.id}');
                  },
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: scheduleAsync.when(
        data: (schedule) {
          if (schedule == null) {
            return const Center(child: Text('予定が見つかりません'));
          }

          return RefreshIndicator(
            key: refreshKey,
            onRefresh: handleRefresh,
            child: ListView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  schedule.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Text(
                  schedule.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '開始: ${_formatDateTime(schedule.startDateTime)}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '終了: ${_formatDateTime(schedule.endDateTime)}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (schedule.location != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  schedule.location!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // リアクションウィジェット（強制再レンダリングのためのキーを使用）
                    KeyedSubtree(
                      key: reactionKey,
                      child: Column(
                        children: [
                          PopupMenuButton<ReactionType>(
                            child: _buildReactionIcon(interactionState),
                            onSelected: (ReactionType type) {
                              if (currentUserId != null) {
                                ref
                                    .read(scheduleInteractionNotifierProvider(
                                            schedule.id)
                                        .notifier)
                                    .toggleReaction(currentUserId, type)
                                    .then((_) {
                                  // リアクション後に明示的に状態を再読み込み
                                  ref.invalidate(
                                      scheduleInteractionNotifierProvider(
                                          schedule.id));
                                });
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: ReactionType.going,
                                child: Row(
                                  children: [
                                    const Text('🙋 '),
                                    const Text('行きます！'),
                                    const Spacer(),
                                    if (currentUserId != null &&
                                        interactionState
                                                .getUserReaction(currentUserId)
                                                ?.type ==
                                            ReactionType.going)
                                      const Icon(Icons.check,
                                          color: Colors.green),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: ReactionType.thinking,
                                child: Row(
                                  children: [
                                    const Text('🤔 '),
                                    const Text('考え中...'),
                                    const Spacer(),
                                    if (currentUserId != null &&
                                        interactionState
                                                .getUserReaction(currentUserId)
                                                ?.type ==
                                            ReactionType.thinking)
                                      const Icon(Icons.check,
                                          color: Colors.green),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Text(
                            interactionState.reactionCounts.values
                                .fold(0, (a, b) => a + b)
                                .toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    // コメントウィジェット（強制再レンダリングのためのキーを使用）
                    KeyedSubtree(
                      key: commentKey,
                      child: Column(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.comment,
                              color: interactionState.commentCount > 0
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              _showCommentsBottomSheet(
                                  context, ref, schedule.id, currentUserId);
                            },
                          ),
                          Text(
                            interactionState.commentCount.toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // コメントリスト表示（最新3件）
                if (interactionState.comments.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'コメント',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: interactionState.comments.length > 3
                              ? 3
                              : interactionState.comments.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final comment = interactionState.comments[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundImage: comment.userPhotoUrl != null &&
                                        comment.userPhotoUrl!.isNotEmpty
                                    ? NetworkImage(comment.userPhotoUrl!)
                                    : null,
                                backgroundColor: comment.userPhotoUrl == null ||
                                        comment.userPhotoUrl!.isEmpty
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.2)
                                    : null,
                                child: comment.userPhotoUrl == null ||
                                        comment.userPhotoUrl!.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(comment.userDisplayName ?? '不明なユーザー'),
                              subtitle: Text(comment.content),
                              trailing: Text(
                                '${comment.createdAt.month}/${comment.createdAt.day} ${comment.createdAt.hour}:${comment.createdAt.minute.toString().padLeft(2, '0')}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            );
                          },
                        ),
                      ),
                      if (interactionState.comments.length > 3)
                        TextButton(
                          onPressed: () {
                            _showCommentsBottomSheet(
                                context, ref, schedule.id, currentUserId);
                          },
                          child: const Text('すべてのコメントを表示'),
                        ),
                    ],
                  ),
                // コンテンツが少ない場合でもスクロールできるようにするためのスペーサー
                SizedBox(height: MediaQuery.of(context).size.height * 0.5),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('エラー: ${error.toString()}')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 手動でリフレッシュを実行
          AppLogger.debug('ScheduleDetailPage: FABからリフレッシュを実行');
          if (scrollController.hasClients) {
            // 画面を一番上までスクロール
            scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
          // リフレッシュ表示の呼び出し
          refreshKey.currentState?.show();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showCommentsBottomSheet(
      BuildContext context, WidgetRef ref, String scheduleId, String? userId) {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return HookConsumer(
                builder: (context, ref, child) {
                  // インタラクション状態の監視
                  final interactionState = ref
                      .watch(scheduleInteractionNotifierProvider(scheduleId));

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'コメント',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: interactionState.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : interactionState.comments.isEmpty
                                ? const Center(child: Text('コメントはまだありません'))
                                : ListView.separated(
                                    controller: scrollController,
                                    itemCount: interactionState.comments.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(),
                                    itemBuilder: (context, index) {
                                      final comment =
                                          interactionState.comments[index];
                                      final isCurrentUser =
                                          userId == comment.userId;

                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage:
                                              comment.userPhotoUrl != null &&
                                                      comment.userPhotoUrl!
                                                          .isNotEmpty
                                                  ? NetworkImage(
                                                      comment.userPhotoUrl!)
                                                  : null,
                                          backgroundColor:
                                              comment.userPhotoUrl == null ||
                                                      comment
                                                          .userPhotoUrl!.isEmpty
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.2)
                                                  : null,
                                          child: comment.userPhotoUrl == null ||
                                                  comment.userPhotoUrl!.isEmpty
                                              ? const Icon(Icons.person)
                                              : null,
                                        ),
                                        title: Row(
                                          children: [
                                            Text(comment.userDisplayName ??
                                                '不明なユーザー'),
                                            if (isCurrentUser) ...[
                                              const SizedBox(width: 8),
                                              const Chip(
                                                label: Text('自分'),
                                                padding: EdgeInsets.all(0),
                                                labelStyle:
                                                    TextStyle(fontSize: 10),
                                              ),
                                            ],
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(comment.content),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${comment.createdAt.year}/${comment.createdAt.month}/${comment.createdAt.day} ${comment.createdAt.hour}:${comment.createdAt.minute.toString().padLeft(2, '0')}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                        trailing: isCurrentUser
                                            ? IconButton(
                                                icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 18),
                                                onPressed: () {
                                                  ref
                                                      .read(
                                                          scheduleInteractionNotifierProvider(
                                                                  scheduleId)
                                                              .notifier)
                                                      .deleteComment(comment.id)
                                                      .then((_) {
                                                    // コメント削除後に明示的に状態を再読み込み
                                                    ref.invalidate(
                                                        scheduleInteractionNotifierProvider(
                                                            scheduleId));
                                                  });
                                                },
                                              )
                                            : null,
                                      );
                                    },
                                  ),
                      ),
                      if (userId != null) ...[
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: textController,
                                  decoration: const InputDecoration(
                                    hintText: 'コメントを入力...',
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(24)),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  maxLines: null,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: () {
                                  if (textController.text.trim().isNotEmpty) {
                                    ref
                                        .read(
                                            scheduleInteractionNotifierProvider(
                                                    scheduleId)
                                                .notifier)
                                        .addComment(
                                            userId, textController.text.trim())
                                        .then((_) {
                                      // コメント追加後に明示的に状態を再読み込み
                                      ref.invalidate(
                                          scheduleInteractionNotifierProvider(
                                              scheduleId));
                                    });
                                    textController.clear();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildReactionIcon(ScheduleInteractionState interactionState) {
    final goingCount = interactionState.reactionCounts[ReactionType.going] ?? 0;
    final thinkingCount =
        interactionState.reactionCounts[ReactionType.thinking] ?? 0;

    // リアクションがない場合
    if (goingCount == 0 && thinkingCount == 0) {
      return const Icon(
        Icons.favorite_border,
        color: Colors.grey,
      );
    }
    // 「行きます！」のみの場合
    else if (goingCount > 0 && thinkingCount == 0) {
      return const Text(
        '🙋',
        style: TextStyle(fontSize: 24),
      );
    }
    // 「考え中」のみの場合
    else if (goingCount == 0 && thinkingCount > 0) {
      return const Text(
        '🤔',
        style: TextStyle(fontSize: 24),
      );
    }
    // 両方存在する場合
    else {
      return Stack(
        children: [
          const Text(
            '🙋',
            style: TextStyle(fontSize: 24),
          ),
          Positioned(
            right: -10,
            bottom: -10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '🤔',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      );
    }
  }
}

// 現在のユーザーIDを取得するためのProvider
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.whenOrNull(
    data: (state) => state.user?.id,
  );
});

// スケジュール情報を取得するためのProvider
final scheduleProvider = StreamProvider.family<Schedule?, String>(
  (ref, scheduleId) {
    return ref
        .watch(scheduleNotifierProvider.notifier)
        .watchSchedule(scheduleId);
  },
);
