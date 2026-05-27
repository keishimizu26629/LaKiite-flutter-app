import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/calendar/widgets/schedule_list_card.dart';

class DailyScheduleListPage extends StatelessWidget {
  const DailyScheduleListPage({
    required this.date,
    required this.schedules,
    required this.currentUserId,
    super.key,
  });

  final DateTime date;
  final List<Schedule> schedules;
  final String? currentUserId;

  String _formatDate(DateTime date) {
    final weekDays = ['日', '月', '火', '水', '木', '金', '土'];
    final weekDay = weekDays[date.weekday % 7];
    return '${DateFormat('yyyy年M月d日').format(date)}（$weekDay）';
  }

  String _formatTimeRange(Schedule schedule) {
    final formatter = DateFormat('HH:mm');
    return '${formatter.format(schedule.startDateTime)}〜'
        '${formatter.format(schedule.endDateTime)}';
  }

  @override
  Widget build(BuildContext context) {
    final allDaySchedules = schedules
        .where((schedule) => schedule.isAllDay)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final timedSchedules =
        schedules.where((schedule) => !schedule.isAllDay).toList()
          ..sort((a, b) {
            final startComparison = a.startDateTime.compareTo(b.startDateTime);
            if (startComparison != 0) {
              return startComparison;
            }
            return a.createdAt.compareTo(b.createdAt);
          });

    return Scaffold(
      appBar: AppBar(title: const Text('予定一覧')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            _formatDate(date),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...allDaySchedules.map(
            (schedule) => ScheduleListCard(
              schedule: schedule,
              currentUserId: currentUserId,
            ),
          ),
          ...timedSchedules.map(
            (schedule) => ScheduleListCard(
              schedule: schedule,
              currentUserId: currentUserId,
              trailingText: _formatTimeRange(schedule),
            ),
          ),
        ],
      ),
    );
  }
}
