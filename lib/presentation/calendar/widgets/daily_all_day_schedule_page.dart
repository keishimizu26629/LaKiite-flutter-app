import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/calendar/widgets/all_day_schedule_card.dart';

class DailyAllDaySchedulePage extends StatelessWidget {
  const DailyAllDaySchedulePage({
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

  @override
  Widget build(BuildContext context) {
    final sortedSchedules = List<Schedule>.from(schedules)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Scaffold(
      appBar: AppBar(title: const Text('終日予定')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            _formatDate(date),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...sortedSchedules.map(
            (schedule) => AllDayScheduleCard(
              schedule: schedule,
              currentUserId: currentUserId,
            ),
          ),
        ],
      ),
    );
  }
}
