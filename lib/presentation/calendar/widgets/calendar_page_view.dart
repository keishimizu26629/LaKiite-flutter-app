import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/presentation/calendar/widgets/daily_schedule_view.dart';
import 'package:lakiite/presentation/theme/app_theme.dart';
import 'package:lakiite/presentation/calendar/create_schedule_page.dart';
import 'dart:convert';
import 'dart:async'; // Timerのインポートを追加
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/services.dart' show rootBundle;
import 'package:lakiite/utils/logger.dart'; // AppLoggerのインポートを追加

// 現在表示中のカレンダーページインデックスを保持するプロバイダー
final calendarCurrentIndexProvider =
    AutoDisposeStateNotifierProvider<CalendarIndexNotifier, int>(
        (ref) => CalendarIndexNotifier());

// カレンダーインデックスを管理するStateNotifier
class CalendarIndexNotifier extends StateNotifier<int> {
  CalendarIndexNotifier() : super(1200);

  void update(int index) {
    state = index;
  }

  void reset() {
    state = 1200;
  }
}

// 初期表示の最適化フラグ
bool _isCalendarFirstBuild = true;

// スライド中かどうかを管理するフラグ
bool _isSliding = false;
Timer? _slidingTimer;

// PageControllerをキャッシュするプロバイダー
final calendarPageControllerProvider = Provider<PageController>((ref) {
  // 現在のインデックスを取得
  final currentIndex = ref.watch(calendarCurrentIndexProvider);

  // PageControllerを作成（ページ切り替えアニメーション速度を最適化）
  final controller = PageController(
    initialPage: currentIndex,
    viewportFraction: 1.0,
    keepPage: true,
  );

  // PageControllerが破棄されるときの処理
  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

// 直前に読み込みリクエストが行われた時間を記録するプロバイダー
final lastDataFetchTimeProvider = StateProvider<DateTime?>((ref) => null);

// 読み込みスロットリングの最小間隔（ミリ秒）
const int _minFetchIntervalMillis = 500;

// 祝日データを取得して永続的にキャッシュするプロバイダー
final holidaysProvider = FutureProvider<Map<String, String>>((ref) async {
  final String jsonString =
      await rootBundle.loadString('assets/data/japanese_holidays.json');
  final Map<String, dynamic> jsonMap = json.decode(jsonString);
  return Map<String, String>.from(jsonMap);
});

// 事前にキャッシュする祝日データを管理するプロバイダー
final cachedHolidaysProvider = StateProvider<Map<String, String>>((ref) => {});

// 表示月ごとにスケジュールデータの読み込み状態を管理
final monthDataLoadingProvider =
    StateProvider.family<bool, String>((ref, monthKey) => false);

// カレンダー表示用の月キーを生成
String getMonthKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

// 何ヶ月先のデータまで先読みするか
const int _prefetchMonthsRange = 2;

// 事前にレンダリングする月の数（前後_preRenderMonthsRange月）
const int _preRenderMonthsRange = 2;

// 表示されていない月のページをクリアする間隔
const int _cleanupIntervalMillis = 60000; // 1分

// 可能な限り軽量なカレンダー表示を行うための最適化プロバイダー
final calendarOptimizationProvider = StateProvider<bool>((ref) => true);

// 既に作成済みの月ページを管理するプロバイダー
final renderedMonthsProvider = StateProvider<Set<int>>((ref) => {});

// スケジュールデータのキャッシュプロバイダー
final cachedSchedulesProvider =
    StateProvider<Map<String, List<Schedule>>>((ref) => {});

// 最後にクリーンアップを実行した時間
final lastCleanupTimeProvider = StateProvider<DateTime?>((ref) => null);

// 表示中および前後の月のインデックスを管理するプロバイダー
final activeMonthIndicesProvider = StateProvider<Set<int>>((ref) => {1200});

class CalendarPageView extends HookConsumerWidget {
  const CalendarPageView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndexValue = ref.watch(calendarCurrentIndexProvider);
    final activeMonthIndices = ref.watch(activeMonthIndicesProvider);
    final renderedMonths = ref.watch(renderedMonthsProvider);

    final visibleDateTime = _getVisibleDateTime(currentIndexValue);
    final visibleMonth = _getMonthName(visibleDateTime.month);
    final visibleYear = visibleDateTime.year.toString();
    ref.watch(authNotifierProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    // 最適化モードの取得
    ref.watch(calendarOptimizationProvider);

    // 初期表示時は最適化モードをオフにして通常表示にする
    if (_isCalendarFirstBuild) {
      _isCalendarFirstBuild = false;
      // ビルド完了後に実行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.exists(calendarOptimizationProvider)) {
          ref.read(calendarOptimizationProvider.notifier).state = false;
        }
      });
    }

    // キャッシュされたPageControllerを使用
    final pageController = ref.watch(calendarPageControllerProvider);

    // スクロール状態を管理するためのコントローラ
    final scrollStarted = useRef(false);

    // ページの同期処理（初期表示時のみ）
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (pageController.hasClients) {
            final currentPage = pageController.page?.round() ?? -1;

            // ページが期待値と異なる場合は修正
            if (currentPage != currentIndexValue && currentPage != -1) {
              pageController.jumpToPage(currentIndexValue);
            }

            // 初期表示時に前後の月をレンダリング済みとしてマーク
            final initialRenderedMonths = <int>{currentIndexValue};
            for (int i = 1; i <= _preRenderMonthsRange; i++) {
              initialRenderedMonths.add(currentIndexValue - i);
              initialRenderedMonths.add(currentIndexValue + i);
            }
            if (ref.exists(renderedMonthsProvider)) {
              ref.read(renderedMonthsProvider.notifier).state =
                  initialRenderedMonths;
            }
          }
        } catch (e) {
          AppLogger.error('初期ページ同期エラー: $e');
        }
      });
      return null;
    }, []);

    // 祝日データを先読み
    useEffect(() {
      final holidaysAsync = ref.watch(holidaysProvider);

      holidaysAsync.whenData((holidays) {
        // 祝日データをキャッシュ（すぐに利用できるようにする）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            if (ref.exists(cachedHolidaysProvider)) {
              ref.read(cachedHolidaysProvider.notifier).state = holidays;
            }
          } catch (e) {
            AppLogger.error('祝日データキャッシュエラー: $e');
          }
        });
      });

      return null;
    }, []);

    // 初期表示時にデータを取得
    useEffect(() {
      if (currentUserId != null) {
        final visibleDate = _getVisibleDateTime(currentIndexValue);

        // ビルド完了後に実行（ウィジェットツリーの構築中に状態を変更しないため）
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            // まず祝日データを確実に読み込む
            final holidaysAsync = ref.read(holidaysProvider);
            holidaysAsync.whenData((holidays) {
              try {
                if (ref.exists(cachedHolidaysProvider)) {
                  ref.read(cachedHolidaysProvider.notifier).state = holidays;
                }

                // 祝日データが読み込まれた後でスケジュールデータを取得
                // ページ初期表示時は常にデータを取得
                _fetchDataWithThrottle(ref, currentUserId, visibleDate, true);

                // 前後の月のデータも事前に取得
                for (int i = 1; i <= _prefetchMonthsRange; i++) {
                  // 前の月
                  final prevDate =
                      DateTime(visibleDate.year, visibleDate.month - i, 1);
                  _fetchDataWithThrottle(ref, currentUserId, prevDate, false);

                  // 次の月
                  final nextDate =
                      DateTime(visibleDate.year, visibleDate.month + i, 1);
                  _fetchDataWithThrottle(ref, currentUserId, nextDate, false);
                }
              } catch (e) {
                AppLogger.error('祝日データ反映エラー: $e');
              }
            });

            // 前後の月のインデックス集合を初期化
            final newIndices = <int>{currentIndexValue};
            for (int i = 1; i <= _prefetchMonthsRange; i++) {
              newIndices.add(currentIndexValue - i);
              newIndices.add(currentIndexValue + i);
            }

            if (ref.exists(activeMonthIndicesProvider)) {
              ref.read(activeMonthIndicesProvider.notifier).state = newIndices;
            }

            // 定期的なクリーンアップを開始
            _scheduleCleanup(ref, currentIndexValue);
          } catch (e) {
            AppLogger.error('初期データ読み込みエラー: $e');
          }
        });
      }
      return null;
    }, [currentUserId]);

    // 可能な限りキャッシュを再利用するページビュー
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
          // ローディングインジケーター（現在表示中の月のデータ読み込み状態を表示）
          Consumer(
            builder: (context, ref, child) {
              final currentMonthKey = getMonthKey(visibleDateTime);
              final isLoading =
                  ref.watch(monthDataLoadingProvider(currentMonthKey));
              return isLoading
                  ? const LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      minHeight: 2,
                    )
                  : const SizedBox(height: 2);
            },
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                // スクロール開始時
                if (notification is ScrollStartNotification) {
                  _isSliding = true;
                  scrollStarted.value = true;

                  // スクロール中は最適化モードを有効にして軽量レンダリング
                  if (ref.exists(calendarOptimizationProvider)) {
                    ref.read(calendarOptimizationProvider.notifier).state =
                        true;
                  }
                }
                // スクロール終了時
                else if (notification is ScrollEndNotification &&
                    scrollStarted.value) {
                  scrollStarted.value = false;

                  // タイマーをキャンセルして再設定
                  _slidingTimer?.cancel();
                  _slidingTimer = Timer(const Duration(milliseconds: 300), () {
                    _isSliding = false;

                    // スライド完了後に最適化モードを無効化
                    if (ref.exists(calendarOptimizationProvider)) {
                      ref.read(calendarOptimizationProvider.notifier).state =
                          false;
                    }

                    // スライド完了後にデータを再取得（必要な場合のみ）
                    if (currentUserId != null) {
                      final currentIndex =
                          ref.read(calendarCurrentIndexProvider);
                      final visibleDate = _getVisibleDateTime(currentIndex);
                      _fetchDataWithThrottle(
                          ref, currentUserId, visibleDate, true);
                    }
                  });
                }
                return false;
              },
              child: PageView.builder(
                controller: pageController,
                physics: const OptimizedScrollPhysics(),
                // スクロール開始時に最適化モードを有効化
                dragStartBehavior: DragStartBehavior.start,
                itemBuilder: (context, index) {
                  // インデックスが事前レンダリング範囲外で未レンダリングの場合は空のプレースホルダーを表示
                  final isPreRendered =
                      (index >= currentIndexValue - _preRenderMonthsRange &&
                          index <= currentIndexValue + _preRenderMonthsRange);
                  final isAlreadyRendered = renderedMonths.contains(index);

                  if (!isPreRendered && !isAlreadyRendered) {
                    // 事前レンダリング範囲外で未レンダリングの場合は時間差でレンダリングをスケジュール
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (ref.exists(renderedMonthsProvider)) {
                        final current = ref.read(renderedMonthsProvider);
                        if (!current.contains(index)) {
                          ref.read(renderedMonthsProvider.notifier).state = {
                            ...current,
                            index
                          };
                        }
                      }
                    });

                    // 軽量なプレースホルダーを表示
                    return CalendarPlaceholder(
                      key: ValueKey('calendar_placeholder_$index'),
                      index: index,
                    );
                  }

                  final dateTime = _getVisibleDateTime(index);
                  final monthKey = getMonthKey(dateTime);

                  // アクティブな範囲内のページにキープアライブを適用
                  final shouldCache = activeMonthIndices.contains(index);

                  // キーを追加して再構築を防止
                  return RepaintBoundary(
                    child: shouldCache
                        ? KeepAliveCalendarPage(
                            key: ValueKey(
                                'calendar_page_${dateTime.year}_${dateTime.month}'),
                            visiblePageDate: dateTime,
                            monthKey: monthKey,
                          )
                        : CalendarPageFrame(
                            key: ValueKey(
                                'calendar_page_${dateTime.year}_${dateTime.month}'),
                            visiblePageDate: dateTime,
                            monthKey: monthKey,
                          ),
                  );
                },
                onPageChanged: (index) {
                  // ビルド中に状態を変更しないよう、非同期処理で実行
                  Future.microtask(() {
                    try {
                      // 前回のインデックスと大きく異なる場合はジャンプを制限
                      final currentIndex =
                          ref.read(calendarCurrentIndexProvider);
                      if ((index - currentIndex).abs() > 15) {
                        // 極端なジャンプを制限し、制御された移動を行う
                        final safeIndex = index > currentIndex
                            ? currentIndex + 15
                            : currentIndex - 15;

                        // 安全なインデックスに更新
                        if (ref.exists(calendarCurrentIndexProvider)) {
                          ref
                              .read(calendarCurrentIndexProvider.notifier)
                              .update(safeIndex);
                        }

                        // ページコントローラーを安全なインデックスに合わせる
                        Future.delayed(const Duration(milliseconds: 50), () {
                          if (pageController.hasClients) {
                            try {
                              pageController.jumpToPage(safeIndex);
                            } catch (e) {
                              AppLogger.error('ページジャンプエラー: $e');
                            }
                          }
                        });

                        return; // 極端なジャンプを防止
                      }

                      // インデックスを状態プロバイダーに保存
                      if (index >= 800 && index <= 1600) {
                        if (ref.exists(calendarCurrentIndexProvider)) {
                          ref
                              .read(calendarCurrentIndexProvider.notifier)
                              .update(index);
                        }

                        // 表示する月を取得
                        final visibleDate = _getVisibleDateTime(index);

                        // 祝日データを確実に先読み - 新しいアプローチ（軽量化）
                        if (!_isSliding &&
                            ref.exists(holidaysProvider) &&
                            ref.exists(cachedHolidaysProvider)) {
                          final cachedHolidays =
                              ref.read(cachedHolidaysProvider);
                          if (cachedHolidays.isEmpty) {
                            ref.read(holidaysProvider).whenData((holidays) {
                              try {
                                ref
                                    .read(cachedHolidaysProvider.notifier)
                                    .state = holidays;
                              } catch (e) {
                                AppLogger.error('ページ変更時祝日キャッシュエラー: $e');
                              }
                            });
                          }
                        }

                        // スライド中でなければアクティブな月インデックスの集合を更新
                        if (!_isSliding) {
                          final newIndices = <int>{index};
                          for (int i = 1; i <= _prefetchMonthsRange; i++) {
                            newIndices.add(index - i);
                            newIndices.add(index + i);
                          }

                          if (ref.exists(activeMonthIndicesProvider)) {
                            ref
                                .read(activeMonthIndicesProvider.notifier)
                                .state = newIndices;
                          }
                        }

                        // スライド中でなければ新しく表示される月を先読みでレンダリング
                        if (!_isSliding && ref.exists(renderedMonthsProvider)) {
                          final currentRendered =
                              ref.read(renderedMonthsProvider);
                          final additionalMonths = <int>{};

                          for (int i = 1; i <= _preRenderMonthsRange; i++) {
                            if (!currentRendered.contains(index + i)) {
                              additionalMonths.add(index + i);
                            }
                            if (!currentRendered.contains(index - i)) {
                              additionalMonths.add(index - i);
                            }
                          }

                          if (additionalMonths.isNotEmpty) {
                            ref.read(renderedMonthsProvider.notifier).state = {
                              ...currentRendered,
                              ...additionalMonths
                            };
                          }
                        }

                        // スライド中でない場合のみデータ取得を実行
                        if (!_isSliding && currentUserId != null) {
                          _fetchDataWithThrottle(
                              ref, currentUserId, visibleDate);

                          // データ取得後にクリーンアップをスケジュール
                          _scheduleCleanup(ref, index);
                        }
                      } else {
                        // 異常なインデックスの場合はリセット
                        if (ref.exists(calendarCurrentIndexProvider)) {
                          ref
                              .read(calendarCurrentIndexProvider.notifier)
                              .reset();
                        }
                      }
                    } catch (e) {
                      AppLogger.error('ページ変更エラー: $e');
                      // エラーが発生した場合は現在のインデックスに戻る
                      try {
                        if (ref.exists(calendarCurrentIndexProvider)) {
                          ref
                              .read(calendarCurrentIndexProvider.notifier)
                              .reset();
                        }
                      } catch (_) {
                        // リセット自体が失敗した場合は無視
                      }
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 不要なページのクリーンアップをスケジュール
  void _scheduleCleanup(WidgetRef ref, int currentIndex) {
    final lastCleanup = ref.read(lastCleanupTimeProvider);
    final now = DateTime.now();

    // 前回のクリーンアップから一定時間経過している場合のみ実行
    if (lastCleanup == null ||
        now.difference(lastCleanup).inMilliseconds > _cleanupIntervalMillis) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!ref.exists(renderedMonthsProvider) ||
            !ref.exists(lastCleanupTimeProvider)) return;

        // 現在のアクティブ範囲を取得
        final activeIndices = ref.read(activeMonthIndicesProvider);
        final renderedIndices = ref.read(renderedMonthsProvider);

        // 拡張された保持範囲（前後6ヶ月は保持）
        const retainRange = 6;
        final retainIndices = <int>{currentIndex};
        for (int i = 1; i <= retainRange; i++) {
          retainIndices.add(currentIndex - i);
          retainIndices.add(currentIndex + i);
        }

        // アクティブ範囲外かつ保持範囲外のインデックスをフィルタリング
        final toRemove = renderedIndices
            .where((idx) =>
                !activeIndices.contains(idx) && !retainIndices.contains(idx))
            .toSet();

        // 削除対象がある場合、レンダリング済みセットから除外
        if (toRemove.isNotEmpty) {
          ref.read(renderedMonthsProvider.notifier).state = {
            ...renderedIndices.difference(toRemove)
          };
        }

        // クリーンアップ時間を更新
        ref.read(lastCleanupTimeProvider.notifier).state = now;
      });
    }
  }

  // スロットリングを適用してデータ取得
  void _fetchDataWithThrottle(WidgetRef ref, String userId, DateTime date,
      [bool force = false]) {
    try {
      final monthKey = getMonthKey(date);

      // Providerの存在確認
      if (!ref.exists(lastDataFetchTimeProvider) ||
          !ref.exists(cachedSchedulesProvider) ||
          !ref.exists(monthDataLoadingProvider(monthKey))) {
        return;
      }

      final lastFetchTime = ref.read(lastDataFetchTimeProvider);
      final now = DateTime.now();

      // キャッシュチェック
      final cachedSchedules = ref.read(cachedSchedulesProvider);
      final hasCachedData = cachedSchedules.containsKey(monthKey);

      // 読み込み状態を取得
      final isLoading = ref.read(monthDataLoadingProvider(monthKey));
      final isFirstLoad = lastFetchTime == null;

      // スライド中は不要なデータ取得をスキップ
      if (_isSliding && !force) {
        return;
      }

      // 強制フラグがある、または前回の読み込みから一定時間経過している場合に読み込み
      if (force ||
          isFirstLoad ||
          !isLoading &&
              (!hasCachedData ||
                  now.difference(lastFetchTime).inMilliseconds >
                      _minFetchIntervalMillis)) {
        // 読み込み状態を更新
        ref.read(monthDataLoadingProvider(monthKey).notifier).state = true;
        ref.read(lastDataFetchTimeProvider.notifier).state = now;

        try {
          // APIリクエスト
          if (ref.exists(scheduleNotifierProvider)) {
            ref
                .read(scheduleNotifierProvider.notifier)
                .watchUserSchedulesForMonth(userId, date);

            // 一定時間後にローディング状態を解除
            Future.delayed(const Duration(milliseconds: 1000), () {
              try {
                if (ref.exists(monthDataLoadingProvider(monthKey))) {
                  ref.read(monthDataLoadingProvider(monthKey).notifier).state =
                      false;
                }
              } catch (e) {
                AppLogger.error('ローディング状態解除エラー: $e');
              }
            });
          }
        } catch (e) {
          AppLogger.error('スケジュールデータ取得エラー: $e');
          // エラー時も読み込み状態を解除
          Future.delayed(const Duration(milliseconds: 300), () {
            try {
              if (ref.exists(monthDataLoadingProvider(monthKey))) {
                ref.read(monthDataLoadingProvider(monthKey).notifier).state =
                    false;
              }
            } catch (_) {
              // 無視
            }
          });
        }
      }
    } catch (e) {
      AppLogger.error('データ取得処理エラー: $e');
    }
  }

  // 指定した範囲の月の祝日データを先読み

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
    // 現在の日時を取得（基準日時）
    final now = DateTime.now().toUtc().toLocal();

    // インデックスの妥当性チェック（範囲を拡大）
    if (index < 800 || index > 1600) {
      // 異常値の場合は現在の月を返す
      return DateTime(now.year, now.month);
    }

    final monthDif = index - 1200;

    // 基準日時の年月を取得
    final baseYear = now.year;
    final baseMonth = now.month;

    // 基準日時からの月数の差分を計算
    final totalMonths = baseYear * 12 + baseMonth + monthDif;

    // 年と月を計算
    final targetYear = totalMonths ~/ 12;
    final targetMonth = totalMonths % 12;

    // 月が0になる場合は前年の12月を意味する
    final adjustedMonth = targetMonth == 0 ? 12 : targetMonth;
    final adjustedYear = targetMonth == 0 ? targetYear - 1 : targetYear;

    // 極端な年をチェック
    if (adjustedYear < now.year - 20 || adjustedYear > now.year + 20) {
      // 異常値の場合は現在の月を返す
      return DateTime(now.year, now.month);
    }

    return DateTime(adjustedYear, adjustedMonth);
  }
}

// カレンダーの枠組みを表示するウィジェット（データがなくても表示可能）
class CalendarPageFrame extends StatelessWidget {
  const CalendarPageFrame({
    required this.visiblePageDate,
    required this.monthKey,
    super.key,
  });

  final DateTime visiblePageDate;
  final String monthKey;

  @override
  Widget build(BuildContext context) {
    return CalendarPageContent(
      visiblePageDate: visiblePageDate,
      monthKey: monthKey,
    );
  }
}

// 自動キャッシュされる月表示ページ
class KeepAliveCalendarPage extends StatefulWidget {
  const KeepAliveCalendarPage({
    required this.visiblePageDate,
    required this.monthKey,
    super.key,
  });

  final DateTime visiblePageDate;
  final String monthKey;

  @override
  State<KeepAliveCalendarPage> createState() => _KeepAliveCalendarPageState();
}

class _KeepAliveCalendarPageState extends State<KeepAliveCalendarPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return CalendarPageContent(
      visiblePageDate: widget.visiblePageDate,
      monthKey: widget.monthKey,
    );
  }
}

// カレンダーの内容（データと枠組みを分離）
class CalendarPageContent extends HookConsumerWidget {
  const CalendarPageContent({
    required this.visiblePageDate,
    required this.monthKey,
    super.key,
  });

  final DateTime visiblePageDate;
  final String monthKey;

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

  // より効率的なスケジュールマップの生成
  Map<String, List<Schedule>> _generateOptimizedScheduleMap(
      List<DateTime> dates,
      List<Schedule> schedules,
      DateTime visibleMonth,
      bool optimized) {
    final Map<String, List<Schedule>> result = {};

    // 日付キーを事前に作成
    for (final date in dates) {
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      result[dateKey] = [];
    }

    // 表示する最大スケジュール数を制限
    final maxSchedules = optimized ? 30 : schedules.length;
    final schedulesToProcess = schedules.take(maxSchedules).toList();

    // 各スケジュールの日付範囲をあらかじめ計算
    final scheduleDateRanges = <Schedule, (DateTime, DateTime)>{};
    for (final schedule in schedulesToProcess) {
      final startDate = DateTime(
        schedule.startDateTime.year,
        schedule.startDateTime.month,
        schedule.startDateTime.day,
      );

      final endDate = DateTime(
        schedule.endDateTime.year,
        schedule.endDateTime.month,
        schedule.endDateTime.day,
      );

      scheduleDateRanges[schedule] = (startDate, endDate);
    }

    // 最適化モード時は表示月のみ処理
    if (optimized) {
      final relevantDates =
          dates.where((date) => date.month == visibleMonth.month).toList();

      for (final date in relevantDates) {
        final targetDate = DateTime(date.year, date.month, date.day);
        final dateKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        for (final entry in scheduleDateRanges.entries) {
          final schedule = entry.key;
          final (startDate, endDate) = entry.value;

          if (!targetDate.isBefore(startDate) && !targetDate.isAfter(endDate)) {
            result[dateKey]?.add(schedule);
          }
        }
      }
      return result;
    }

    // 通常モードでは全ての日付を処理
    for (final date in dates) {
      final targetDate = DateTime(date.year, date.month, date.day);
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      for (final entry in scheduleDateRanges.entries) {
        final schedule = entry.key;
        final (startDate, endDate) = entry.value;

        if (!targetDate.isBefore(startDate) && !targetDate.isAfter(endDate)) {
          result[dateKey]?.add(schedule);
        }
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 最適化モードの取得
    final isOptimized = ref.watch(calendarOptimizationProvider);

    // メモ化して再計算を防止
    final currentDates =
        useMemoized(() => _getCurrentDates(visiblePageDate), [visiblePageDate]);

    // キャッシュされたスケジュールデータを取得
    final cachedSchedules = ref.watch(cachedSchedulesProvider);

    // スケジュールデータを取得（ローディング中はプレースホルダーを表示）
    final scheduleState = ref.watch(scheduleNotifierProvider);

    // スケジュールデータを取得（キャッシュ優先）
    final schedules = useMemoized(() {
      // 最適化モード時はキャッシュを優先
      if (isOptimized && cachedSchedules.isNotEmpty) {
        return scheduleState.maybeWhen(
          data: (state) => state.maybeMap(
            loaded: (loaded) {
              // スライド中でなければキャッシュを更新
              if (!_isSliding) {
                Future.microtask(() {
                  try {
                    ref.read(cachedSchedulesProvider.notifier).state = {
                      ...cachedSchedules,
                      ...loaded.schedules.fold<Map<String, List<Schedule>>>(
                        {},
                        (map, schedule) {
                          final key =
                              '${schedule.startDateTime.year}-${schedule.startDateTime.month}';
                          map[key] = [...(map[key] ?? []), schedule];
                          return map;
                        },
                      ),
                    };
                  } catch (e) {
                    AppLogger.error('キャッシュ更新エラー: $e');
                  }
                });
              }
              return loaded.schedules;
            },
            orElse: () => <Schedule>[],
          ),
          orElse: () => <Schedule>[],
        );
      }

      return scheduleState.when(
        data: (state) => state.maybeMap(
          loaded: (loaded) {
            // スライド中でなければキャッシュを更新
            if (!_isSliding) {
              Future.microtask(() {
                try {
                  ref.read(cachedSchedulesProvider.notifier).state = {
                    ...cachedSchedules,
                    ...loaded.schedules.fold<Map<String, List<Schedule>>>(
                      {},
                      (map, schedule) {
                        final key =
                            '${schedule.startDateTime.year}-${schedule.startDateTime.month}';
                        map[key] = [...(map[key] ?? []), schedule];
                        return map;
                      },
                    ),
                  };
                } catch (e) {
                  AppLogger.error('キャッシュ更新エラー: $e');
                }
              });
            }
            return loaded.schedules;
          },
          orElse: () => <Schedule>[],
        ),
        loading: () => <Schedule>[],
        error: (_, __) => <Schedule>[],
      );
    }, [scheduleState, isOptimized, cachedSchedules, _isSliding]);

    // 日付ごとにスケジュールをフィルタリング（最適化）- 高速アルゴリズムを使用
    final dateSchedulesMap = useMemoized(() {
      return _generateOptimizedScheduleMap(
          currentDates, schedules, visiblePageDate, isOptimized);
    }, [currentDates, schedules, visiblePageDate, isOptimized]);

    // 日付別セルを事前に計算してパフォーマンスを向上（最適化モードではシンプルなセル）
    final dateCells = useMemoized(
        () => List.generate(6, (rowIndex) {
              final rowDates =
                  currentDates.sublist(rowIndex * 7, (rowIndex + 1) * 7);

              // 最適化モードでは簡易表示
              if (isOptimized) {
                return OptimizedDatesRow(
                  rowIndex: rowIndex,
                  dates: rowDates,
                  dateSchedulesMap: dateSchedulesMap,
                  visibleMonth: visiblePageDate,
                );
              }

              return DatesRow(
                dates: rowDates,
                dateSchedulesMap: dateSchedulesMap,
                visibleMonth: visiblePageDate,
              );
            }),
        [currentDates, dateSchedulesMap, visiblePageDate, isOptimized]);

    // パフォーマンス最適化のためのコンテナ
    return RepaintBoundary(
      child: isOptimized
          ? OptimizedCalendarLayout(
              children: [const DaysOfTheWeek(), ...dateCells],
            )
          : Column(
              children: [const DaysOfTheWeek(), ...dateCells],
            ),
    );
  }
}

// 曜日ヘッダー
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

// 日付行
class DatesRow extends StatelessWidget {
  const DatesRow({
    required this.dates,
    required this.dateSchedulesMap,
    required this.visibleMonth,
    super.key,
  });

  final List<DateTime> dates;
  final Map<String, List<Schedule>> dateSchedulesMap;
  final DateTime visibleMonth;

  @override
  Widget build(BuildContext context) {
    // 各日付のセルを事前に計算
    final dateCells = dates.map((date) {
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final dateSchedules = dateSchedulesMap[dateString] ?? [];

      return Expanded(
        child: DateCell(
          key: ValueKey('date_$dateString'),
          date: date,
          schedules: dateSchedules,
          visibleMonth: visibleMonth,
        ),
      );
    }).toList();

    return Expanded(
      child: Row(children: dateCells),
    );
  }
}

// パフォーマンス最適化された日付セル
class DateCell extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    // 計算を1回だけ行う
    final isToday = _isToday(date);
    final isWeekend = date.weekday == DateTime.sunday;
    final isSaturday = date.weekday == DateTime.saturday;
    final isCurrentMonth = date.month == visibleMonth.month;
    final currentUserId = ref.watch(currentUserIdProvider);

    // 祝日のチェック（コンテキストからProviderScopeを取得）
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    Map<String, String> cachedHolidays = {};
    bool isHoliday = false;

    try {
      // 安全に祝日データを取得
      if (ProviderScope.containerOf(context).exists(cachedHolidaysProvider)) {
        cachedHolidays =
            ProviderScope.containerOf(context).read(cachedHolidaysProvider);
        isHoliday = cachedHolidays.containsKey(dateString);
      }
    } catch (e) {
      // エラーが発生した場合は祝日ではないとみなす
      isHoliday = false;
    }

    // キャッシュにない場合は非同期で取得
    if (cachedHolidays.isEmpty) {
      final holidaysAsync = ref.watch(holidaysProvider);

      return holidaysAsync.when(
        data: (holidays) {
          final isHolidayFromAsync = holidays.containsKey(dateString);

          return OptimizedDateCell(
            date: date,
            schedules: schedules,
            isToday: isToday,
            isWeekend: isWeekend,
            isSaturday: isSaturday,
            isCurrentMonth: isCurrentMonth,
            isHoliday: isHolidayFromAsync,
            holidayName: holidays[dateString] ?? '',
            currentUserId: currentUserId,
          );
        },
        loading: () => OptimizedDateCell(
          date: date,
          schedules: schedules,
          isToday: isToday,
          isWeekend: isWeekend,
          isSaturday: isSaturday,
          isCurrentMonth: isCurrentMonth,
          isHoliday: false,
          holidayName: '',
          currentUserId: currentUserId,
        ),
        error: (_, __) => OptimizedDateCell(
          date: date,
          schedules: schedules,
          isToday: isToday,
          isWeekend: isWeekend,
          isSaturday: isSaturday,
          isCurrentMonth: isCurrentMonth,
          isHoliday: false,
          holidayName: '',
          currentUserId: currentUserId,
        ),
      );
    }

    // キャッシュから即時に取得
    return OptimizedDateCell(
      date: date,
      schedules: schedules,
      isToday: isToday,
      isWeekend: isWeekend,
      isSaturday: isSaturday,
      isCurrentMonth: isCurrentMonth,
      isHoliday: isHoliday,
      holidayName: cachedHolidays[dateString] ?? '',
      currentUserId: currentUserId,
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now().toUtc().toLocal();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

// パフォーマンス最適化のために分離したDateCell実装
class OptimizedDateCell extends StatelessWidget {
  const OptimizedDateCell({
    required this.date,
    required this.schedules,
    required this.isToday,
    required this.isWeekend,
    required this.isSaturday,
    required this.isCurrentMonth,
    required this.isHoliday,
    required this.holidayName,
    required this.currentUserId,
    super.key,
  });

  final DateTime date;
  final List<Schedule> schedules;
  final bool isToday;
  final bool isWeekend;
  final bool isSaturday;
  final bool isCurrentMonth;
  final bool isHoliday;
  final String holidayName;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    // 事前レンダリング最適化のためのフラグ
    final hasSchedules = schedules.isNotEmpty;
    final cellColor = isToday
        ? Colors.blue.shade50
        : !isCurrentMonth
            ? Colors.grey.shade100
            : null;
    final dayTextColor = isHoliday || isWeekend
        ? AppTheme.weekendColor
        : isSaturday
            ? Colors.blue
            : !isCurrentMonth
                ? Colors.grey.shade500
                : null;

    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // 選択された日付をProviderに保存
            ProviderScope.containerOf(context)
                .read(selectedDateProvider.notifier)
                .state = date;

            // DailyScheduleViewに遷移
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DailyScheduleView(
                  initialDate: date,
                  schedules: const [], // 軽量版なのでスケジュールは空で渡す
                ),
              ),
            );
          },
          child: Stack(
            children: [
              // 背景のコンテナ（変更が少ない）
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                          color: Theme.of(context).dividerColor, width: 1),
                      right: BorderSide(
                          color: Theme.of(context).dividerColor, width: 1),
                    ),
                    color: cellColor,
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
                        color: dayTextColor,
                        fontWeight: isToday ? FontWeight.bold : null,
                        fontSize: 12,
                      ),
                    ),
                    if (hasSchedules) ...[
                      const SizedBox(height: 1),
                      ...schedules.take(3).map((schedule) {
                        final isOwner = schedule.ownerId == currentUserId;
                        // デバッグログを追加
                        AppLogger.debug(
                            'OptimizedDateCell - 予定: ${schedule.title}, オーナーID: ${schedule.ownerId}, currentUserId: $currentUserId, isOwner: $isOwner');

                        // ユーザーIDが未定義でない場合のみ判定を行う
                        final isOwnerWithCheck = currentUserId != null &&
                            schedule.ownerId == currentUserId;
                        AppLogger.debug(
                            'OptimizedDateCell - 判定結果: ${schedule.title}, 単純比較=$isOwner, チェック付き=$isOwnerWithCheck');

                        return Container(
                          margin: const EdgeInsets.only(bottom: 0.5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 0.5),
                          decoration: BoxDecoration(
                            color: isOwnerWithCheck
                                ? Colors.grey.shade200
                                : Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.15),
                            border: Border.all(
                              color: isOwnerWithCheck
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
                              color: isOwnerWithCheck
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
  }
}

// スクロール最適化パフォーマンス向上
class OptimizedScrollPhysics extends ScrollPhysics {
  const OptimizedScrollPhysics({super.parent});

  @override
  OptimizedScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return OptimizedScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.25, // さらに軽く
        stiffness: 350.0, // 剛性を上げる
        damping: 30.0, // 減衰をさらに強化
      );

  @override
  double get maxFlingVelocity => 800.0; // 速度上限をさらに下げる

  @override
  double get minFlingVelocity => 70.0; // 最小速度を上げる

  @override
  double get dragStartDistanceMotionThreshold => 10.0; // ドラッグ開始しきい値を上げる
}

// スクロール中の軽量表示用ウィジェット
class OptimizedCalendarLayout extends StatelessWidget {
  const OptimizedCalendarLayout({
    required this.children,
    super.key,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        children: children,
      ),
    );
  }
}

// スクロール中の軽量表示用の行
class OptimizedDatesRow extends StatelessWidget {
  const OptimizedDatesRow({
    required this.rowIndex,
    required this.dates,
    required this.dateSchedulesMap,
    required this.visibleMonth,
    super.key,
  });

  final int rowIndex;
  final List<DateTime> dates;
  final Map<String, List<Schedule>> dateSchedulesMap;
  final DateTime visibleMonth;

  @override
  Widget build(BuildContext context) {
    // シンプルな日付セル（軽量化のためスケジュール詳細は表示しない）
    final dateCells = dates.map((date) {
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final hasSchedules = (dateSchedulesMap[dateString]?.isNotEmpty ?? false);

      // 軽量セル
      return Expanded(
        child: LightweightDateCell(
          key: ValueKey('date_lite_$dateString'),
          date: date,
          hasSchedules: hasSchedules,
          visibleMonth: visibleMonth,
        ),
      );
    }).toList();

    return Expanded(
      child: RepaintBoundary(
        child: Row(children: dateCells),
      ),
    );
  }
}

// 軽量な日付セル（スクロール中の表示用）
class LightweightDateCell extends StatelessWidget {
  const LightweightDateCell({
    required this.date,
    required this.hasSchedules,
    required this.visibleMonth,
    super.key,
  });

  final DateTime date;
  final bool hasSchedules;
  final DateTime visibleMonth;

  @override
  Widget build(BuildContext context) {
    // 最小限の計算のみ行う
    final isCurrentMonth = date.month == visibleMonth.month;
    final isWeekend = date.weekday == DateTime.sunday;
    final isSaturday = date.weekday == DateTime.saturday;
    final isToday = _isToday(date);

    // 祝日のチェック（コンテキストからProviderScopeを取得）
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    Map<String, String> cachedHolidays = {};
    bool isHoliday = false;

    try {
      // 安全に祝日データを取得
      if (ProviderScope.containerOf(context).exists(cachedHolidaysProvider)) {
        cachedHolidays =
            ProviderScope.containerOf(context).read(cachedHolidaysProvider);
        isHoliday = cachedHolidays.containsKey(dateString);
      }
    } catch (e) {
      // エラーが発生した場合は祝日ではないとみなす
      isHoliday = false;
    }

    // 日付の色を決定
    final dayTextColor = isHoliday || isWeekend
        ? AppTheme.weekendColor
        : isSaturday
            ? Colors.blue
            : !isCurrentMonth
                ? Colors.grey.shade500
                : null;

    final cellColor = isToday
        ? Colors.blue.shade50
        : !isCurrentMonth
            ? Colors.grey.shade100
            : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // 選択された日付をProviderに保存
          ProviderScope.containerOf(context)
              .read(selectedDateProvider.notifier)
              .state = date;

          // DailyScheduleViewに遷移
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DailyScheduleView(
                initialDate: date,
                schedules: const [], // 軽量版なのでスケジュールは空で渡す
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
              right:
                  BorderSide(color: Theme.of(context).dividerColor, width: 1),
            ),
            color: cellColor,
          ),
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date.day.toString(),
                style: TextStyle(
                  color: dayTextColor,
                  fontWeight: isToday ? FontWeight.bold : null,
                  fontSize: 12,
                ),
              ),
              if (hasSchedules)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  height: 3,
                  width: 10,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now().toUtc().toLocal();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

// 未レンダリングページのプレースホルダー
class CalendarPlaceholder extends StatelessWidget {
  const CalendarPlaceholder({
    required this.index,
    super.key,
  });

  final int index;

  @override
  Widget build(BuildContext context) {
    // 軽量なプレースホルダー（グレーの背景と骨組みのみ）
    return Column(
      children: [
        // 曜日部分のプレースホルダー
        const DaysOfTheWeek(),
        // 日付グリッド部分（6週間分の枠を表示）
        Expanded(
          child: Column(
            children: List.generate(
              6,
              (row) => Expanded(
                child: Row(
                  children: List.generate(
                    7,
                    (col) => Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                            right: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                          color: Colors.grey.shade50,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
