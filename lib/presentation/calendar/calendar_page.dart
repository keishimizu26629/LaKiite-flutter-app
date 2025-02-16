import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/presentation/calendar/create_schedule_page.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/calendar/widgets/calendar_page_view.dart';
import 'package:lakiite/presentation/calendar/schedule_detail_page.dart';
import 'package:lakiite/presentation/theme/app_theme.dart';

class CalendarPage extends HookConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final initialized = useState(false);
    final userId = useState<String?>(null);

    useEffect(() {
      if (!authState.hasValue) return null;

      authState.whenData((state) {
        if (state.status == AuthStatus.authenticated && state.user != null) {
          final currentUserId = state.user!.id;
          
          if (!initialized.value || userId.value != currentUserId) {
            initialized.value = true;
            userId.value = currentUserId;
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(scheduleNotifierProvider.notifier).watchUserSchedules(currentUserId);
              ref.read(listNotifierProvider.notifier).watchUserLists(currentUserId);
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
          initialIndex: 1, // タイムラインを最初に表示
          child: Scaffold(
            appBar: AppBar(
              title: const Text(
                'スケジュール',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: AppTheme.primaryColor,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: Colors.white,
                  child: const TabBar(
                    tabs: [
                      Tab(text: 'カレンダー'),
                      Tab(text: 'タイムライン'),
                    ],
                  ),
                ),
              ),
            ),
            body: TabBarView(
              children: [
                // カレンダー表示タブ
                scheduleState.when(
                  data: (_) => const CalendarPageView(),
                  error: (error, _) => _buildErrorWidget(context, ref, state, error),
                  loading: () => const Center(child: CircularProgressIndicator()),
                ),
                // タイムライン表示タブ
                scheduleState.when(
                  data: (scheduleState) => scheduleState.maybeMap(
                    loaded: (loaded) {
                      if (loaded.schedules.isEmpty) {
                        return const Center(child: Text('予定がありません'));
                      }
                      return _buildTimelineList(
                        context,
                        loaded.schedules,
                        state.user!,
                        ref,
                      );
                    },
                    orElse: () => const Center(child: Text('予定がありません')),
                  ),
                  error: (error, _) => _buildErrorWidget(context, ref, state, error),
                  loading: () => const Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateSchedulePage(),
                  ),
                );
              },
              child: const Icon(Icons.add),
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

  Widget _buildTimelineList(
    BuildContext context,
    List<Schedule> schedules,
    UserModel currentUser,
    WidgetRef ref,
  ) {
    final sortedSchedules = List<Schedule>.from(schedules)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return ListView.builder(
      itemCount: sortedSchedules.length,
      itemBuilder: (context, index) {
        final schedule = sortedSchedules[index];
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          color: schedule.ownerId == currentUser.id
              ? const Color(0xFFfff5e6) // プライマリカラーの最も薄い色
              : null,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ScheduleDetailPage(schedule: schedule),
                ),
              );
            },
            child: ListTile(
              title: Row(
                children: [
                  Expanded(child: Text(schedule.title)),
                  if (schedule.ownerId == currentUser.id) ...[
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => CreateSchedulePage(
                              schedule: schedule,
                            ),
                          ),
                        );
                      },
                    ),
                    const Chip(
                      label: Text('作成者'),
                      backgroundColor: const Color(0xFFffa600),
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  ],
                ],
              ),
              subtitle: FutureBuilder<UserModel?>(
                future: ref.read(userRepositoryProvider).getUser(schedule.ownerId),
                builder: (context, snapshot) {
                  final ownerName = snapshot.hasData
                      ? snapshot.data!.displayName
                      : '読み込み中...';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(schedule.description),
                      if (schedule.location != null)
                        Text('場所: ${schedule.location}'),
                      Text(
                        '日時: ${DateFormat('yyyy/MM/dd HH:mm').format(schedule.dateTime)}',
                      ),
                      Text('作成者: $ownerName'),
                    ],
                  );
                },
              ),
            ),
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
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text('エラーが発生しました: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(scheduleNotifierProvider.notifier)
                  .watchUserSchedules(state.user!.id);
            },
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }
}
