import 'package:flutter/material.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/presentation/calendar/schedule_detail_page.dart';

class DailyScheduleContent extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final sortedSchedules = List<Schedule>.from(schedules)
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

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
                  if (date.year == DateTime.now().year &&
                      date.month == DateTime.now().month &&
                      date.day == DateTime.now().day)
                    Positioned(
                      top: _calculateTimePosition(DateTime.now()),
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  // スケジュール
                  ...sortedSchedules.map((schedule) {
                    final startTime = schedule.startDateTime;
                    final endTime = schedule.endDateTime;

                    return Positioned(
                      top: _calculateTimePosition(startTime),
                      left: 0,
                      right: 0,
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
                          height: _calculateHeight(startTime, endTime),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            border: Border.all(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.8),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schedule.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${DateFormat('HH:mm').format(startTime)} - ${DateFormat('HH:mm').format(endTime)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (schedule.location != null &&
                                    _calculateHeight(startTime, endTime) > 60) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 12,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          schedule.location!,
                                          style: TextStyle(
                                            fontSize: 12,
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
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
