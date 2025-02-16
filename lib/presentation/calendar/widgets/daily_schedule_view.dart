import 'package:flutter/material.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/presentation/calendar/schedule_detail_page.dart';
import 'package:lakiite/presentation/theme/app_theme.dart';

class DailyScheduleView extends StatelessWidget {
  const DailyScheduleView({
    required this.date,
    required this.schedules,
    super.key,
  });

  final DateTime date;
  final List<Schedule> schedules;

  @override
  Widget build(BuildContext context) {
    final sortedSchedules = List<Schedule>.from(schedules)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(date)),
      ),
      body: ListView.builder(
        itemCount: 24,
        itemBuilder: (context, hour) {
          final timeSlotSchedules = sortedSchedules.where((schedule) {
            return schedule.dateTime.hour == hour &&
                   schedule.dateTime.year == date.year &&
                   schedule.dateTime.month == date.month &&
                   schedule.dateTime.day == date.day;
          }).toList();

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 60,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        '$hour:00',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const VerticalDivider(),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: timeSlotSchedules.isEmpty
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (timeSlotSchedules.isEmpty)
                            Container(
                              height: 24,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.withOpacity(0.3),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                          else
                            ...timeSlotSchedules.map((schedule) {
                              return InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ScheduleDetailPage(
                                        schedule: schedule,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 2),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        schedule.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (schedule.location != null)
                                        Text(
                                          '📍 ${schedule.location}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekDays = ['日', '月', '火', '水', '木', '金', '土'];
    final weekDay = weekDays[date.weekday % 7];
    final formatter = DateFormat('yyyy年M月d日');
    return '${formatter.format(date)}（$weekDay）';
  }
}