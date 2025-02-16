import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/presentation/calendar/widgets/daily_schedule_view.dart';
import 'package:lakiite/presentation/theme/app_theme.dart';

class CalendarPageView extends HookConsumerWidget {
  const CalendarPageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final currentIndex = useState(1200);
    final visibleMonth = _getMonthName(_getVisibleDateTime(currentIndex.value).month);
    final visibleYear = _getVisibleDateTime(currentIndex.value).year.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Text(
            "$visibleYear年$visibleMonth",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: PageController(initialPage: 1200),
            itemBuilder: (context, index) {
              final dateTime = _getVisibleDateTime(index);
              return CalendarPage(
                visiblePageDate: dateTime,
                schedules: scheduleState.when(
                  data: (state) => state.maybeMap(
                    loaded: (loaded) => loaded.schedules,
                    orElse: () => <Schedule>[],
                  ),
                  loading: () => <Schedule>[],
                  error: (_, __) => <Schedule>[],
                ),
              );
            },
            onPageChanged: (index) {
              currentIndex.value = index;
            },
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    final monthNames = [
      "1月", "2月", "3月", "4月", "5月", "6月",
      "7月", "8月", "9月", "10月", "11月", "12月"
    ];
    return monthNames[month - 1];
  }

  DateTime _getVisibleDateTime(int index) {
    final monthDif = index - 1200;
    final visibleYear = _getVisibleYear(monthDif);
    final visibleMonth = _getVisibleMonth(monthDif);
    return DateTime(visibleYear, visibleMonth);
  }

  int _getVisibleYear(int monthDif) {
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final visibleMonth = currentMonth + monthDif;

    if (visibleMonth > 0) {
      return currentYear + (visibleMonth ~/ 12);
    } else {
      return currentYear + ((visibleMonth ~/ 12) - 1);
    }
  }

  int _getVisibleMonth(int monthDif) {
    final initialMonth = DateTime.now().month;
    final currentMonth = initialMonth + monthDif;

    if (currentMonth > 0) {
      return currentMonth % 12;
    } else {
      return 12 - (-currentMonth % 12);
    }
  }
}

class CalendarPage extends StatelessWidget {
  const CalendarPage({
    required this.visiblePageDate,
    required this.schedules,
    super.key,
  });

  final DateTime visiblePageDate;
  final List<Schedule> schedules;

  List<DateTime> _getCurrentDates(DateTime dateTime) {
    final List<DateTime> result = [];
    final firstDay = _getFirstDate(dateTime);
    result.add(firstDay);
    for (int i = 0; i + 1 < 42; i++) {
      result.add(firstDay.add(Duration(days: i + 1)));
    }
    return result;
  }

  DateTime _getFirstDate(DateTime dateTime) {
    final firstDayOfTheMonth = DateTime(dateTime.year, dateTime.month, 1);
    return firstDayOfTheMonth.add(_getDaysDuration(firstDayOfTheMonth.weekday));
  }

  Duration _getDaysDuration(int weekday) {
    return Duration(days: (weekday == 7) ? 0 : -weekday);
  }

  List<Schedule> _getSchedulesForDate(DateTime date) {
    return schedules.where((schedule) {
      final scheduleDate = DateTime(
        schedule.dateTime.year,
        schedule.dateTime.month,
        schedule.dateTime.day,
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
  Widget build(BuildContext context) {
    final currentDates = _getCurrentDates(visiblePageDate);
    return Column(
      children: [
        const DaysOfTheWeek(),
        DatesRow(dates: currentDates.getRange(0, 7).toList(), schedules: schedules),
        DatesRow(dates: currentDates.getRange(7, 14).toList(), schedules: schedules),
        DatesRow(dates: currentDates.getRange(14, 21).toList(), schedules: schedules),
        DatesRow(dates: currentDates.getRange(21, 28).toList(), schedules: schedules),
        DatesRow(dates: currentDates.getRange(28, 35).toList(), schedules: schedules),
        DatesRow(dates: currentDates.getRange(35, 42).toList(), schedules: schedules),
      ],
    );
  }
}

class DaysOfTheWeek extends StatelessWidget {
  const DaysOfTheWeek({super.key});

  @override
  Widget build(BuildContext context) {
    const daysOfTheWeek = ['日', '月', '火', '水', '木', '金', '土'];
    return Row(
      children: daysOfTheWeek.map((day) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: day == '日' ? AppTheme.weekendColor : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class DatesRow extends StatelessWidget {
  const DatesRow({
    required this.dates,
    required this.schedules,
    super.key,
  });

  final List<DateTime> dates;
  final List<Schedule> schedules;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: dates.map((date) {
          final dateSchedules = schedules.where((schedule) {
            final scheduleDate = DateTime(
              schedule.dateTime.year,
              schedule.dateTime.month,
              schedule.dateTime.day,
            );
            final targetDate = DateTime(
              date.year,
              date.month,
              date.day,
            );
            return scheduleDate.isAtSameMomentAs(targetDate);
          }).toList();
          return DateCell(date: date, schedules: dateSchedules);
        }).toList(),
      ),
    );
  }
}

class DateCell extends StatelessWidget {
  const DateCell({
    required this.date,
    required this.schedules,
    super.key,
  });

  final DateTime date;
  final List<Schedule> schedules;

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(date);
    final isWeekend = date.weekday == DateTime.sunday || date.weekday == DateTime.saturday;

    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DailyScheduleView(
                date: date,
                schedules: schedules,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
              right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
            ),
            color: isToday ? AppTheme.backgroundColor : null,
            borderRadius: isToday ? BorderRadius.circular(4) : null,
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date.day.toString(),
                style: TextStyle(
                  color: isWeekend ? AppTheme.weekendColor : null,
                  fontWeight: isToday ? FontWeight.bold : null,
                ),
              ),
              if (schedules.isNotEmpty) ...[
                const SizedBox(height: 2),
                ...schedules.take(3).map((schedule) => Text(
                      schedule.title,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    )),
                if (schedules.length > 3)
                  Text(
                    '+${schedules.length - 3}',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}