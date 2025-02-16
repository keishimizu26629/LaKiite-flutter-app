import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/schedule/schedule_interaction_notifier.dart';
import 'package:lakiite/application/schedule/schedule_interaction_state.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/presentation/theme/app_theme.dart';
import 'package:intl/intl.dart';

class ScheduleDetailPage extends HookConsumerWidget {
  const ScheduleDetailPage({
    required this.schedule,
    super.key,
  });

  final Schedule schedule;

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
              // タイトル
              Text(
                schedule.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 日時
              _buildInfoSection(
                icon: Icons.calendar_today,
                title: '日時',
                content: DateFormat('yyyy年M月d日（E） HH:mm', 'ja_JP')
                    .format(schedule.dateTime),
              ),

              // 場所
              if (schedule.location != null)
                _buildInfoSection(
                  icon: Icons.location_on,
                  title: '場所',
                  content: schedule.location!,
                ),

              // 説明
              _buildInfoSection(
                icon: Icons.description,
                title: '説明',
                content: schedule.description,
              ),

              const Divider(height: 32),

              // いいねセクション
              _buildLikesSection(context, interactions),

              const Divider(height: 32),

              // コメントセクション
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

          return BottomAppBar(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  // いいねボタン
                  IconButton(
                    icon: Icon(
                      interactions.isLikedByUser(state.user!.id)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: interactions.isLikedByUser(state.user!.id)
                          ? AppTheme.primaryColor
                          : null,
                    ),
                    onPressed: () {
                      ref
                          .read(scheduleInteractionNotifierProvider(schedule.id)
                              .notifier)
                          .toggleLike(state.user!.id);
                    },
                  ),
                  // コメント入力
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
                  // 送信ボタン
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        ref
                            .read(scheduleInteractionNotifierProvider(schedule.id)
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

  Widget _buildLikesSection(
    BuildContext context,
    ScheduleInteractionState interactions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'いいね ${interactions.likeCount}件',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (interactions.likes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: interactions.likes.map((like) {
              return Chip(
                label: Text(like.userId),
                backgroundColor: AppTheme.backgroundColor,
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

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
                              style: const TextStyle(fontWeight: FontWeight.bold),
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