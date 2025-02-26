import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakiite/presentation/widgets/schedule_tile.dart';
import 'package:lakiite/presentation/calendar/edit_schedule_page.dart';
import '../../presentation_provider.dart';

/// ユーザーの予定一覧を表示するウィジェット
///
/// [userId] ユーザーID
///
/// 予定がない場合は「予定がありません」というメッセージを表示します。
/// 予定がある場合は、日付でソートされたリストを表示します。
class ScheduleList extends ConsumerWidget {
  final String userId;

  const ScheduleList({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(userSchedulesStreamProvider(userId));

    return schedulesAsync.when(
      data: (schedules) {
        // 自分の予定のみをフィルタリング
        final mySchedules =
            schedules.where((s) => s.ownerId == userId).toList();

        if (mySchedules.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_busy,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '予定がありません',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        // 日付でソート
        mySchedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mySchedules.length,
          itemBuilder: (context, index) {
            final schedule = mySchedules[index];
            return ScheduleTile(
              schedule: schedule,
              currentUserId: userId,
              showOwner: false,
              showEditButton: true,
              isTimelineView: false,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              onEditPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => EditSchedulePage(
                      schedule: schedule,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('エラーが発生しました: $error'),
      ),
    );
  }
}
