import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/presentation/calendar/create_schedule_page.dart';
import 'package:lakiite/presentation/calendar/widgets/calendar_page_view.dart';
import 'package:lakiite/presentation/widgets/banner_ad_widget.dart';
import 'package:lakiite/presentation/widgets/notification_button.dart';
import 'package:lakiite/presentation/widgets/schedule_tile.dart';
import 'package:lakiite/utils/logger.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final initialized = useState(false);
    final userId = useState<String?>(null);
    final hideOwnSchedules = useState(false);
    final currentTabIndex = useState(0);

    // TabControllerを取得
    final tabController = DefaultTabController.maybeOf(context);

    // TabControllerのリスナー設定
    useEffect(() {
      if (tabController != null) {
        void listener() {
          // タブが切り替わった時の処理
          if (currentTabIndex.value != tabController.index) {
            // タイムラインからカレンダータブに戻る場合
            if (tabController.index == 0 && currentTabIndex.value == 1) {
              // カレンダーのインデックスをリセット
              ref.read(calendarCurrentIndexProvider.notifier).reset();

              // 選択日付を今日の日付にリセット
              final today = DateTime.now();
              ref.read(selectedDateProvider.notifier).state = today;
              AppLogger.debug(
                  'タブ切り替え: selectedDateProviderを今日の日付にリセットしました: ${today.year}年${today.month}月${today.day}日');

              // PageControllerの位置も1200にリセット
              WidgetsBinding.instance.addPostFrameCallback((_) {
                try {
                  final pageController =
                      ref.read(calendarPageControllerProvider);
                  if (pageController.hasClients) {
                    pageController.jumpToPage(1200);
                    AppLogger.debug('タブ切り替え: PageControllerの位置を1200にリセットしました');
                  } else {
                    AppLogger.debug('タブ切り替え: PageControllerにクライアントがありません');
                  }
                } catch (e) {
                  AppLogger.error(
                      'タブ切り替え: PageControllerのリセット中にエラーが発生しました: $e');
                }
              });
              AppLogger.debug('タブ切り替え: カレンダーインデックスをリセットしました');

              // PageControllerの位置も1200にリセット
              // 複数回のフレーム更新後に実行して、ウィジェットが完全に構築されるのを待つ
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // 最初のフレーム後に実行
                AppLogger.debug('タブ切り替え: 最初のフレーム後');

                // さらに遅延を追加して、ウィジェットが完全に構築されるのを待つ
                Future.delayed(const Duration(milliseconds: 100), () {
                  try {
                    final pageController =
                        ref.read(calendarPageControllerProvider);
                    if (pageController.hasClients) {
                      // jumpToPageではなくanimateToPageを使用して、より確実に移動
                      pageController.jumpToPage(1200);
                      AppLogger.debug(
                          'タブ切り替え: PageControllerの位置を1200にリセットしました');

                      // 追加の検証
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (pageController.hasClients) {
                          final currentPage =
                              pageController.page?.round() ?? -1;
                          AppLogger.debug(
                              'タブ切り替え: 現在のページ = $currentPage (期待値: 1200)');
                        }
                      });
                    } else {
                      AppLogger.debug('タブ切り替え: PageControllerにクライアントがありません');

                      // クライアントがない場合は、さらに遅延を追加して再試行
                      Future.delayed(const Duration(milliseconds: 300), () {
                        try {
                          final retryController =
                              ref.read(calendarPageControllerProvider);
                          if (retryController.hasClients) {
                            retryController.jumpToPage(1200);
                            AppLogger.debug(
                                'タブ切り替え: 再試行 - PageControllerの位置を1200にリセットしました');
                          } else {
                            AppLogger.debug(
                                'タブ切り替え: 再試行 - PageControllerにクライアントがありません');
                          }
                        } catch (e) {
                          AppLogger.error('タブ切り替え: 再試行中にエラーが発生しました: $e');
                        }
                      });
                    }
                  } catch (e) {
                    AppLogger.error(
                        'タブ切り替え: PageControllerのリセット中にエラーが発生しました: $e');
                  }
                });
              });
              AppLogger.debug('タブ切り替え: カレンダーインデックスをリセットしました');
            }
            currentTabIndex.value = tabController.index;
          }
        }

        tabController.addListener(listener);
        return () => tabController.removeListener(listener);
      }
      return null;
    }, [tabController]);

    useEffect(() {
      if (!authState.hasValue) return null;

      authState.whenData((state) {
        if (state.status == AuthStatus.authenticated && state.user != null) {
          final currentUserId = state.user!.id;

          if (!initialized.value || userId.value != currentUserId) {
            initialized.value = true;
            userId.value = currentUserId;

            // 認証完了後、少し遅延させてからスケジュールの取得を開始することで
            // Firebase認証が確実に完了した状態でデータ取得を行う
            Future.delayed(const Duration(milliseconds: 500), () {
              // 常に全ての予定を取得する
              ref
                  .read(scheduleNotifierProvider.notifier)
                  .watchUserSchedules(currentUserId);

              ref
                  .read(listNotifierProvider.notifier)
                  .watchUserLists(currentUserId);

              // データ取得開始をログ出力
              AppLogger.debug(
                  'ホーム画面: 認証完了後のデータ取得を開始しました - userId: $currentUserId');
            });
          }
        }
      });

      return null;
    }, [authState]);

    return authState.when(
      data: (state) {
        if (state.status != AuthStatus.authenticated || state.user == null) {
          return const Scaffold(
            body: Center(
              child: Text('ログインが必要です'),
            ),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                'ホーム',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              actions: const [
                NotificationButton(),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey[600],
                      indicatorColor: Theme.of(context).primaryColor,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 16,
                      ),
                      tabs: const [
                        Tab(text: 'カレンダー'),
                        Tab(text: 'タイムライン'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: TabBarView(
                            children: [
                              // カレンダー表示タブ
                              scheduleState.when(
                                data: (_) => const Column(
                                  children: [
                                    Expanded(child: CalendarPageView()),
                                  ],
                                ),
                                error: (error, _) => _buildErrorWidget(
                                    context, ref, state, error),
                                loading: () => const Center(
                                    child: CircularProgressIndicator()),
                              ),
                              // タイムライン表示タブ
                              scheduleState.when(
                                data: (scheduleState) => scheduleState.maybeMap(
                                  loaded: (loaded) {
                                    // 本日以降のスケジュールをフィルタリング
                                    final today =
                                        DateTime.now().toUtc().toLocal();
                                    final todayStart = DateTime(
                                        today.year, today.month, today.day);

                                    final allSchedules = loaded.schedules;
                                    final filteredByDate =
                                        allSchedules.where((schedule) {
                                      return schedule.endDateTime
                                          .isAfter(todayStart);
                                    }).toList();

                                    // 自分の予定を非表示にするフィルタリング
                                    final filteredSchedules =
                                        hideOwnSchedules.value
                                            ? filteredByDate
                                                .where((s) =>
                                                    s.ownerId != state.user!.id)
                                                .toList()
                                            : filteredByDate;

                                    return Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const Text(
                                                    '自分の予定を非表示',
                                                    style:
                                                        TextStyle(fontSize: 14),
                                                  ),
                                                  Switch(
                                                    value:
                                                        hideOwnSchedules.value,
                                                    onChanged: (value) {
                                                      hideOwnSchedules.value =
                                                          value;
                                                    },
                                                  ),
                                                ],
                                              ),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const CreateSchedulePage(),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.add,
                                                    size: 20),
                                                label: const Text(
                                                  '予定を作成',
                                                  style:
                                                      TextStyle(fontSize: 14),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .primaryColor,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize:
                                                      MaterialTapTargetSize
                                                          .shrinkWrap,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (filteredSchedules.isEmpty)
                                          Expanded(
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.event_busy,
                                                    size: 64,
                                                    color: Colors.grey[400],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    '予定がありません',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        else
                                          Expanded(
                                            child: ListView.builder(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8),
                                              itemCount:
                                                  filteredSchedules.length,
                                              itemBuilder: (context, index) {
                                                final schedule =
                                                    filteredSchedules[index];
                                                return ScheduleTile(
                                                  schedule: schedule,
                                                  currentUserId: state.user!.id,
                                                  showOwner: true,
                                                  showEditButton:
                                                      schedule.ownerId ==
                                                          state.user!.id,
                                                  isTimelineView: true,
                                                  showDivider: false,
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                  orElse: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (error, _) => _buildErrorWidget(
                                    context, ref, state, error),
                                loading: () => const Center(
                                    child: CircularProgressIndicator()),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 50,
                          child: BannerAdWidget(uniqueId: 'home_page_ad'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      error: (error, _) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                Text('認証エラーが発生しました: $error'),
              ],
            ),
          ),
        );
      },
      loading: () {
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    WidgetRef ref,
    AuthState state,
    Object error,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました: $error',
            style: TextStyle(
              color: Theme.of(context).primaryColor.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // 常に全ての予定を取得する
              ref
                  .read(scheduleNotifierProvider.notifier)
                  .watchUserSchedules(state.user!.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }
}
