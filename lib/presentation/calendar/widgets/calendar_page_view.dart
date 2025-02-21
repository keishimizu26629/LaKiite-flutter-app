import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/presentation/calendar/widgets/daily_schedule_view.dart';
import 'package:lakiite/presentation/theme/app_theme.dart';
import 'package:lakiite/presentation/calendar/create_schedule_page.dart';

class CalendarPageView extends HookConsumerWidget {
  const CalendarPageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final currentIndex = useState(1200);
    final visibleMonth =
        _getMonthName(_getVisibleDateTime(currentIndex.value).month);
    final visibleYear = _getVisibleDateTime(currentIndex.value).year.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$visibleYear年$visibleMonth",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateSchedulePage(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text(
                    '予定を作成',
                    style: TextStyle(fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
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
      ),
    );
  }

  String _getMonthName(int month) {
    final monthNames = [
      "1月",
      "2月",
      "3月",
      "4月",
      "5月",
      "6月",
      "7月",
      "8月",
      "9月",
      "10月",
      "11月",
      "12月"
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
      final scheduleStartDate = DateTime(
        schedule.startDateTime.year,
        schedule.startDateTime.month,
        schedule.startDateTime.day,
      );
      final scheduleEndDate = DateTime(
        schedule.endDateTime.year,
        schedule.endDateTime.month,
        schedule.endDateTime.day,
      );
      final targetDate = DateTime(
        date.year,
        date.month,
        date.day,
      );

      // 開始日から終了日までの期間に含まれる場合に表示
      return !targetDate.isBefore(scheduleStartDate) &&
          !targetDate.isAfter(scheduleEndDate);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentDates = _getCurrentDates(visiblePageDate);
    return Column(
      children: [
        const DaysOfTheWeek(),
        DatesRow(
            dates: currentDates.getRange(0, 7).toList(), schedules: schedules),
        DatesRow(
            dates: currentDates.getRange(7, 14).toList(), schedules: schedules),
        DatesRow(
            dates: currentDates.getRange(14, 21).toList(),
            schedules: schedules),
        DatesRow(
            dates: currentDates.getRange(21, 28).toList(),
            schedules: schedules),
        DatesRow(
            dates: currentDates.getRange(28, 35).toList(),
            schedules: schedules),
        DatesRow(
            dates: currentDates.getRange(35, 42).toList(),
            schedules: schedules),
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
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              day,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
            final scheduleStartDate = DateTime(
              schedule.startDateTime.year,
              schedule.startDateTime.month,
              schedule.startDateTime.day,
            );
            final scheduleEndDate = DateTime(
              schedule.endDateTime.year,
              schedule.endDateTime.month,
              schedule.endDateTime.day,
            );
            final targetDate = DateTime(
              date.year,
              date.month,
              date.day,
            );
            return !targetDate.isBefore(scheduleStartDate) &&
                !targetDate.isAfter(scheduleEndDate);
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
    final isWeekend =
        date.weekday == DateTime.sunday || date.weekday == DateTime.saturday;

    return Expanded(
      child: Consumer(
        builder: (context, ref, child) {
          final currentUserId = ref.watch(currentUserIdProvider);
          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DailyScheduleView(
                    initialDate: date,
                    schedules: schedules,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                      color: Theme.of(context).dividerColor, width: 1),
                  right: BorderSide(
                      color: Theme.of(context).dividerColor, width: 1),
                ),
                color: isToday ? Colors.blue.shade50 : null,
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 2,
                        ),
                      ]
                    : null,
                borderRadius: isToday ? BorderRadius.circular(4) : null,
              ),
              padding: const EdgeInsets.all(2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      color: isWeekend ? AppTheme.weekendColor : null,
                      fontWeight: isToday ? FontWeight.bold : null,
                      fontSize: 12,
                    ),
                  ),
                  if (schedules.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    ...schedules.take(2).map((schedule) {
                      final isOwner = schedule.ownerId == currentUserId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 0.5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 1, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: isOwner
                              ? Colors.grey.withOpacity(0.1)
                              : Theme.of(context).primaryColor.withOpacity(0.1),
                          border: Border.all(
                            color: isOwner
                                ? Colors.grey.withOpacity(0.8)
                                : Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.8),
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          schedule.title,
                          style: const TextStyle(fontSize: 8),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                    if (schedules.length > 2)
                      Text(
                        '+${schedules.length - 2}',
                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
