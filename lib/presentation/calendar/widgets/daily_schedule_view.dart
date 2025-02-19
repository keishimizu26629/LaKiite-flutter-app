import 'package:flutter/material.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/presentation/calendar/widgets/daily_schedule_content.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DailyScheduleView extends HookConsumerWidget {
  const DailyScheduleView({
    required this.initialDate,
    required this.schedules,
    super.key,
  });

  final DateTime initialDate;
  final List<Schedule> schedules;

  String _formatDate(DateTime date) {
    final weekDays = ['日', '月', '火', '水', '木', '金', '土'];
    final weekDay = weekDays[date.weekday % 7];
    final formatter = DateFormat('yyyy年M月d日');
    return '${formatter.format(date)}（$weekDay）';
  }

  List<Schedule> _getSchedulesForDate(DateTime date, List<Schedule> allSchedules) {
    return allSchedules.where((schedule) {
      final scheduleDate = DateTime(
        schedule.startDateTime.year,
        schedule.startDateTime.month,
        schedule.startDateTime.day,
      );
      final targetDate = DateTime(
        date.year,
        date.month,
        date.day,
      );
      return scheduleDate.isAtSameMomentAs(targetDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(1000); // 中央のページから開始
    final pageController = usePageController(initialPage: currentIndex.value);
    final currentDate = useState(initialDate);
    final scrollController = useScrollController(
      initialScrollOffset: 6 * 60.0, // 6:00の位置（1時間 = 60.0）
    );

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          // 固定ヘッダー部分
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  _formatDate(currentDate.value),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // スクロール可能なスケジュール部分
          Expanded(
            child: PageView.builder(
              controller: pageController,
              onPageChanged: (index) {
                currentIndex.value = index;
                final difference = index - 1000;
                currentDate.value = initialDate.add(Duration(days: difference));
                // 日付が変わっても6:00の位置にスクロール
                scrollController.jumpTo(6 * 60.0);
              },
              itemBuilder: (context, index) {
                final difference = index - 1000;
                final date = initialDate.add(Duration(days: difference));
                final dateSchedules = _getSchedulesForDate(date, schedules);

                return SingleChildScrollView(
                  controller: scrollController,
                  child: DailyScheduleContent(
                    date: date,
                    schedules: dateSchedules,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
