import 'package:flutter/material.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/presentation/calendar/schedule_detail_page.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/notification/notification_notifier.dart';
import 'package:lakiite/utils/logger.dart';

class DailyScheduleContent extends HookConsumerWidget {
  const DailyScheduleContent({
    required this.date,
    required this.schedules,
    super.key,
  });

  final DateTime date;
  final List<Schedule> schedules;

  double _calculateTimePosition(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    return minutes.toDouble();
  }

  double _calculateHeight(DateTime start, DateTime end) {
    final difference = end.difference(start).inMinutes;
    return difference.toDouble();
  }

  // 重なり合うスケジュールをグループ化する
  List<List<Schedule>> _groupOverlappingSchedules(List<Schedule> schedules) {
    if (schedules.isEmpty) return [];

    List<List<Schedule>> groups = [];
    List<Schedule> currentGroup = [schedules[0]];

    for (int i = 1; i < schedules.length; i++) {
      final currentSchedule = schedules[i];
      bool overlapsWithGroup = false;

      // 現在のグループ内のスケジュールと重なるかチェック
      for (final groupSchedule in currentGroup) {
        if (_isOverlapping(currentSchedule, groupSchedule)) {
          overlapsWithGroup = true;
          break;
        }
      }

      if (overlapsWithGroup) {
        currentGroup.add(currentSchedule);
      } else {
        groups.add(List.from(currentGroup));
        currentGroup = [currentSchedule];
      }
    }

    groups.add(currentGroup);
    return groups;
  }

  // 2つのスケジュールが重なっているかチェック
  bool _isOverlapping(Schedule a, Schedule b) {
    return a.startDateTime.isBefore(b.endDateTime) &&
        b.startDateTime.isBefore(a.endDateTime);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 日付情報をログ出力
    AppLogger.debug(
        'DailyScheduleContent - 表示日付: ${date.year}年${date.month}月${date.day}日');
    AppLogger.debug('DailyScheduleContent - スケジュール数: ${schedules.length}');

    final currentUserId = ref.watch(currentUserIdProvider);
    final sortedSchedules = List<Schedule>.from(schedules)
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    // 重なり合うスケジュールをグループ化
    final scheduleGroups = _groupOverlappingSchedules(sortedSchedules);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 24 * 60.0, // 24時間分の高さ
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 時間表示部分
            SizedBox(
              width: 50,
              child: Stack(
                children: [
                  for (int hour = 0; hour < 24; hour++)
                    Positioned(
                      top: hour * 60.0,
                      child: Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // スケジュール表示部分
            Expanded(
              child: Stack(
                children: [
                  // 時間の区切り線
                  for (int hour = 0; hour < 24; hour++)
                    Positioned(
                      top: hour * 60.0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        color: Colors.grey[200],
                      ),
                    ),
                  // 現在時刻の線
                  if (date.year == DateTime.now().toUtc().toLocal().year &&
                      date.month == DateTime.now().toUtc().toLocal().month &&
                      date.day == DateTime.now().toUtc().toLocal().day)
                    Positioned(
                      top: _calculateTimePosition(
                          DateTime.now().toUtc().toLocal()),
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  // スケジュールグループ
                  ...scheduleGroups.map((group) {
                    final containerWidth = MediaQuery.of(context).size.width -
                        90; // 時間表示部分とパディングの余裕を持たせる
                    return Stack(
                      children: [
                        ...List.generate(group.length, (index) {
                          final schedule = group[index];
                          final startTime = schedule.startDateTime;
                          final endTime = schedule.endDateTime;
                          final isOwner = schedule.ownerId == currentUserId;
                          final itemWidth = group.length == 1
                              ? containerWidth
                              : (containerWidth / group.length) - 4;

                          return Positioned(
                            top: _calculateTimePosition(startTime),
                            left: group.length == 1
                                ? 0
                                : (index * (containerWidth / group.length)),
                            width: itemWidth,
                            height: _calculateHeight(startTime, endTime),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ScheduleDetailPage(schedule: schedule),
                                  ),
                                );
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: isOwner
                                      ? Colors.grey.withOpacity(0.1)
                                      : Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                  border: Border.all(
                                    color: isOwner
                                        ? Colors.grey.withOpacity(0.8)
                                        : Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.8),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        schedule.title,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (schedule.location != null &&
                                          _calculateHeight(startTime, endTime) >
                                              60) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.location_on_outlined,
                                              size: 10,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 2),
                                            Expanded(
                                              child: Text(
                                                schedule.location!,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
