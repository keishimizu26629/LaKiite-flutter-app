import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/presentation/calendar/widgets/daily_schedule_view.dart';
import 'package:lakiite/presentation/theme/app_theme.dart';
import 'package:lakiite/presentation/calendar/create_schedule_page.dart';
import 'package:lakiite/utils/logger.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

// 現在表示中のカレンダーページインデックスを保持するプロバイダー
final calendarCurrentIndexProvider = StateProvider<int>((ref) => 1200);

final holidaysProvider = FutureProvider<Map<String, String>>((ref) async {
  final String jsonString =
      await rootBundle.loadString('assets/data/japanese_holidays.json');
  final Map<String, dynamic> jsonMap = json.decode(jsonString);
  return Map<String, String>.from(jsonMap);
});

class CalendarPageView extends HookConsumerWidget {
  const CalendarPageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(scheduleNotifierProvider);
    // 保存されたインデックスを使用
    final currentIndex = ref.watch(calendarCurrentIndexProvider.notifier);
    final visibleMonth =
        _getMonthName(_getVisibleDateTime(currentIndex.state).month);
    final visibleYear = _getVisibleDateTime(currentIndex.state).year.toString();
    final authState = ref.watch(authNotifierProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    // 前回のスケジュールデータを保持
    final previousSchedules = useState<List<Schedule>>([]);

    // スケジュールデータが更新されたら保存
    useEffect(() {
      scheduleState.whenData((state) {
        state.maybeMap(
          loaded: (loaded) {
            previousSchedules.value = loaded.schedules;
          },
          orElse: () {},
        );
      });
      return null;
    }, [scheduleState]);

    // PageControllerを作成し、保存されたインデックスを初期ページとして使用
    final pageController =
        useMemoized(() => PageController(initialPage: currentIndex.state), []);

    // コントローラーの破棄を適切に行う
    useEffect(() {
      return () {
        pageController.dispose();
      };
    }, [pageController]);

    // 初期表示時に現在の月のデータを取得
    useEffect(() {
      if (currentUserId != null) {
        final visibleDate = _getVisibleDateTime(currentIndex.state);
        AppLogger.debug('初期表示時の月: ${visibleDate.year}-${visibleDate.month}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref
              .read(scheduleNotifierProvider.notifier)
              .watchUserSchedulesForMonth(currentUserId, visibleDate);
        });
      }
      return null;
    }, [currentUserId]);

    // スケジュールデータを取得（ローディング中は前回のデータを表示）
    final schedules = scheduleState.when(
      data: (state) => state.maybeMap(
        loaded: (loaded) => loaded.schedules,
        orElse: () => <Schedule>[],
      ),
      loading: () => previousSchedules.value,
      error: (_, __) => previousSchedules.value,
    );

    // ローディング中かどうかを判定
    final isLoading = scheduleState.isLoading;

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
          // ローディングインジケーターを表示（データは維持したまま）
          if (isLoading)
            const LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              minHeight: 2,
            ),
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemBuilder: (context, index) {
                final dateTime = _getVisibleDateTime(index);
                return CalendarPage(
                  visiblePageDate: dateTime,
                  schedules: schedules,
                );
              },
              onPageChanged: (index) {
                // インデックスを状態プロバイダーに保存
                currentIndex.state = index;
                AppLogger.debug('ページ変更: インデックス=$index');

                // ページ変更時に表示月に基づいてデータを取得
                if (currentUserId != null) {
                  final visibleDate = _getVisibleDateTime(index);
                  AppLogger.debug(
                      '表示月変更: ${visibleDate.year}-${visibleDate.month}');
                  ref
                      .read(scheduleNotifierProvider.notifier)
                      .watchUserSchedulesForMonth(currentUserId, visibleDate);
                }
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
    AppLogger.debug(
        '_getVisibleDateTime: index=$index, monthDif=$monthDif, year=$visibleYear, month=$visibleMonth');
    return DateTime(visibleYear, visibleMonth);
  }

  int _getVisibleYear(int monthDif) {
    // DateTime.now()の代わりに、タイムゾーンを明示的に指定
    final now = DateTime.now().toLocal();
    final currentMonth = now.month;
    final currentYear = now.year;

    // 現在の月に差分を加える
    final targetMonthValue = currentMonth + monthDif;

    // 年の調整を計算
    int yearAdjustment;
    if (targetMonthValue > 0) {
      // 正の値の場合は単純に12で割った商
      yearAdjustment = (targetMonthValue - 1) ~/ 12;
    } else {
      // 負の値の場合は、-1ヶ月が前年の12月になるように調整
      yearAdjustment = (targetMonthValue - 12) ~/ 12;
    }

    final result = currentYear + yearAdjustment;
    AppLogger.debug(
        '_getVisibleYear: monthDif=$monthDif, targetMonthValue=$targetMonthValue, yearAdjustment=$yearAdjustment, result=$result');
    return result;
  }

  int _getVisibleMonth(int monthDif) {
    // DateTime.now()の代わりに、タイムゾーンを明示的に指定
    final now = DateTime.now().toLocal();
    final initialMonth = now.month;
    final targetMonthValue = initialMonth + monthDif;

    // 1〜12の範囲に変換
    int result;
    if (targetMonthValue > 0) {
      result = ((targetMonthValue - 1) % 12) + 1;
    } else {
      // 負の値の場合、-1→12月、-2→11月...となるように調整
      result = 12 - ((-targetMonthValue) % 12);
      if (result == 12 && targetMonthValue % 12 != 0) {
        result = 12;
      }
    }

    AppLogger.debug(
        '_getVisibleMonth: monthDif=$monthDif, targetMonthValue=$targetMonthValue, result=$result');
    return result;
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

  @override
  Widget build(BuildContext context) {
    final currentDates = _getCurrentDates(visiblePageDate);
    return Column(
      children: [
        const DaysOfTheWeek(),
        DatesRow(
            dates: currentDates.getRange(0, 7).toList(),
            schedules: schedules,
            visibleMonth: visiblePageDate),
        DatesRow(
            dates: currentDates.getRange(7, 14).toList(),
            schedules: schedules,
            visibleMonth: visiblePageDate),
        DatesRow(
            dates: currentDates.getRange(14, 21).toList(),
            schedules: schedules,
            visibleMonth: visiblePageDate),
        DatesRow(
            dates: currentDates.getRange(21, 28).toList(),
            schedules: schedules,
            visibleMonth: visiblePageDate),
        DatesRow(
            dates: currentDates.getRange(28, 35).toList(),
            schedules: schedules,
            visibleMonth: visiblePageDate),
        DatesRow(
            dates: currentDates.getRange(35, 42).toList(),
            schedules: schedules,
            visibleMonth: visiblePageDate),
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
                color: day == '日'
                    ? AppTheme.weekendColor
                    : day == '土'
                        ? Colors.blue
                        : null,
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
    required this.visibleMonth,
    super.key,
  });

  final List<DateTime> dates;
  final List<Schedule> schedules;
  final DateTime visibleMonth;

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
          return DateCell(
              date: date, schedules: dateSchedules, visibleMonth: visibleMonth);
        }).toList(),
      ),
    );
  }
}

class DateCell extends StatelessWidget {
  const DateCell({
    required this.date,
    required this.schedules,
    required this.visibleMonth,
    super.key,
  });

  final DateTime date;
  final List<Schedule> schedules;
  final DateTime visibleMonth;

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(date);
    final isWeekend = date.weekday == DateTime.sunday;
    final isSaturday = date.weekday == DateTime.saturday;
    final isCurrentMonth = date.month == visibleMonth.month;

    return Expanded(
      child: Consumer(
        builder: (context, ref, child) {
          final currentUserId = ref.watch(currentUserIdProvider);
          final holidaysAsync = ref.watch(holidaysProvider);

          return holidaysAsync.when(
            data: (holidays) {
              final dateString =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              final isHoliday = holidays.containsKey(dateString);

              // デバッグ用のログ出力
              AppLogger.debug('Date: $dateString, isHoliday: $isHoliday');
              if (isHoliday) {
                AppLogger.debug('Holiday name: ${holidays[dateString]}');
              }

              return Material(
                color: Colors.transparent,
                child: InkWell(
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
                  child: Stack(
                    children: [
                      // 背景のコンテナ
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 1),
                              right: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                  width: 1),
                            ),
                            color: isToday
                                ? Colors.blue.shade50
                                : !isCurrentMonth
                                    ? Colors.grey.shade100
                                    : null,
                          ),
                        ),
                      ),
                      // 日付と予定を表示するコンテナ
                      Container(
                        padding: const EdgeInsets.all(2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date.day.toString(),
                              style: TextStyle(
                                color: isHoliday || isWeekend
                                    ? AppTheme.weekendColor
                                    : isSaturday
                                        ? Colors.blue
                                        : !isCurrentMonth
                                            ? Colors.grey.shade500
                                            : null,
                                fontWeight: isToday ? FontWeight.bold : null,
                                fontSize: 12,
                              ),
                            ),
                            if (schedules.isNotEmpty) ...[
                              const SizedBox(height: 1),
                              ...schedules.take(3).map((schedule) {
                                final isOwner =
                                    schedule.ownerId == currentUserId;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 0.5),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 0.5),
                                  decoration: BoxDecoration(
                                    color: isOwner
                                        ? Colors.grey.shade200
                                        : Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.15),
                                    border: Border.all(
                                      color: isOwner
                                          ? Colors.grey.shade400
                                          : Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    schedule.title,
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: isOwner
                                          ? Colors.grey.shade700
                                          : Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                              if (schedules.length > 3)
                                Padding(
                                  padding: const EdgeInsets.only(top: 0.5),
                                  child: Text(
                                    '+${schedules.length - 3}',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Material(
              color: Colors.transparent,
              child: InkWell(
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
                child: Stack(
                  children: [
                    // 背景のコンテナ
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1),
                            right: BorderSide(
                                color: Theme.of(context).dividerColor,
                                width: 1),
                          ),
                          color: isToday
                              ? Colors.blue.shade50
                              : !isCurrentMonth
                                  ? Colors.grey.shade100
                                  : null,
                        ),
                      ),
                    ),
                    // 日付と予定を表示するコンテナ
                    Container(
                      padding: const EdgeInsets.all(2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            date.day.toString(),
                            style: TextStyle(
                              color: isWeekend
                                  ? AppTheme.weekendColor
                                  : isSaturday
                                      ? Colors.blue
                                      : !isCurrentMonth
                                          ? Colors.grey.shade500
                                          : null,
                              fontWeight: isToday ? FontWeight.bold : null,
                              fontSize: 12,
                            ),
                          ),
                          if (schedules.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            ...schedules.take(3).map((schedule) {
                              final isOwner = schedule.ownerId == currentUserId;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 0.5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 2, vertical: 0.5),
                                decoration: BoxDecoration(
                                  color: isOwner
                                      ? Colors.grey.shade200
                                      : Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.15),
                                  border: Border.all(
                                    color: isOwner
                                        ? Colors.grey.shade400
                                        : Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.3),
                                    width: 0.5,
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: Text(
                                  schedule.title,
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: isOwner
                                        ? Colors.grey.shade700
                                        : Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                            if (schedules.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 0.5),
                                child: Text(
                                  '+${schedules.length - 3}',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now().toLocal();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
