import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/schedule/schedule_notifier.dart';
import '../../application/auth/auth_notifier.dart';
import '../../domain/entity/schedule.dart';

class ScheduleDetailPage extends ConsumerWidget {
  final String scheduleId;

  const ScheduleDetailPage({
    Key? key,
    required this.scheduleId,
  }) : super(key: key);

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month}/${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(scheduleProvider(scheduleId));
    final currentUserId = ref.watch(currentUserIdProvider);

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '終了: ${_formatDateTime(schedule.endDateTime)}',
                                    style: Theme.of(context).textTheme.bodyMedium,
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
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.favorite,
                            color: schedule.reactionCount > 0
                                ? Colors.red
                                : Colors.grey,
                          ),
                          onPressed: () {
                            // TODO: リアクション機能の実装
                          },
                        ),
                        Text(
                          schedule.reactionCount.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.comment,
                            color: schedule.commentCount > 0
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          onPressed: () {
                            // TODO: コメント機能の実装
                          },
                        ),
                        Text(
                          schedule.commentCount.toString(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // TODO: コメントリストの実装
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('エラー: ${error.toString()}')),
      ),
    );
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
    return ref.watch(scheduleNotifierProvider.notifier).watchSchedule(scheduleId);
  },
);
