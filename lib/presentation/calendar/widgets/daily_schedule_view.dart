import 'package:flutter/material.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/presentation/calendar/widgets/daily_schedule_content.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/presentation/presentation_provider.dart'
    hide scheduleNotifierProvider;
import 'package:lakiite/application/schedule/schedule_notifier.dart';
import 'package:lakiite/utils/logger.dart';

class DailyScheduleView extends HookConsumerWidget {
  const DailyScheduleView({
    this.initialDate,
    required this.schedules,
    super.key,
  });

  final DateTime? initialDate;
  final List<Schedule> schedules;

  String _formatDate(DateTime date) {
    final weekDays = ['日', '月', '火', '水', '木', '金', '土'];
    final weekDay = weekDays[date.weekday % 7];
    final formatter = DateFormat('yyyy年M月d日');
    return '${formatter.format(date)}（$weekDay）';
  }

  List<Schedule> _getSchedulesForDate(
      DateTime date, List<Schedule> allSchedules) {
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

    // selectedDateProviderから初期日付を取得
    final selectedDate = ref.watch(selectedDateProvider);
    // initialDateが指定されていればそれを使用し、なければselectedDateを使用
    final effectiveInitialDate = initialDate ?? selectedDate;
    final currentDate = useState(effectiveInitialDate);

    // 日付情報をログ出力
    AppLogger.debug(
        'DailyScheduleView - 初期日付(引数): ${initialDate?.year}年${initialDate?.month}月${initialDate?.day}日 (null=${initialDate == null})');
    AppLogger.debug(
        'DailyScheduleView - selectedDateProviderの日付: ${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日');
    AppLogger.debug(
        'DailyScheduleView - 使用する初期日付: ${effectiveInitialDate.year}年${effectiveInitialDate.month}月${effectiveInitialDate.day}日');
    AppLogger.debug(
        'DailyScheduleView - 現在の表示日付: ${currentDate.value.year}年${currentDate.value.month}月${currentDate.value.day}日');

    final scrollController = useScrollController(
      initialScrollOffset: 6 * 60.0, // 6:00の位置（1時間 = 60.0）
    );

    // スケジュールの状態を監視
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    // 初期化時にスケジュールの監視を開始
    useEffect(() {
      if (currentUserId != null) {
        Future.microtask(() {
          ref
              .read(scheduleNotifierProvider.notifier)
              .watchUserSchedules(currentUserId);
        });
      }
      return null;
    }, [currentUserId]);

    // 日付が変更されたときにProviderを更新
    useEffect(() {
      Future.microtask(() {
        ref.read(selectedDateProvider.notifier).state = currentDate.value;
        AppLogger.debug(
            'DailyScheduleView - selectedDateProviderを更新: ${currentDate.value.year}年${currentDate.value.month}月${currentDate.value.day}日');
      });
      return null;
    }, [currentDate.value]);

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

                // 日付計算の問題を修正
                // 日付の加算は年月をまたぐ場合に問題が発生することがあるため、
                // 年月日を明示的に計算する
                final newDate = DateTime(
                  effectiveInitialDate.year,
                  effectiveInitialDate.month,
                  effectiveInitialDate.day + difference,
                );

                currentDate.value = newDate;
                AppLogger.debug(
                    'DailyScheduleView - ページ変更: インデックス=$index, 差分=$difference日');
                AppLogger.debug(
                    'DailyScheduleView - 新しい表示日付: ${newDate.year}年${newDate.month}月${newDate.day}日');
                // 日付が変わっても6:00の位置にスクロール
                scrollController.jumpTo(6 * 60.0);
              },
              itemBuilder: (context, index) {
                final difference = index - 1000;

                // 同様に、itemBuilderでも日付計算を修正
                final date = DateTime(
                  effectiveInitialDate.year,
                  effectiveInitialDate.month,
                  effectiveInitialDate.day + difference,
                );

                // スケジュール状態から該当日の予定を取得
                final dateSchedules = scheduleState.when(
                  data: (state) => state.when(
                    initial: () => <Schedule>[],
                    loading: () => <Schedule>[],
                    loaded: (schedules) =>
                        _getSchedulesForDate(date, schedules),
                    error: (_) => <Schedule>[],
                    loadingWithData: (schedules) =>
                        _getSchedulesForDate(date, schedules),
                    errorWithData: (schedules, _) =>
                        _getSchedulesForDate(date, schedules),
                  ),
                  loading: () => <Schedule>[],
                  error: (_, __) => <Schedule>[],
                );

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
