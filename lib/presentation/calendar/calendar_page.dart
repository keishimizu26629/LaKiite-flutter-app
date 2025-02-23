import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:intl/intl.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/presentation/calendar/create_schedule_page.dart';
import 'package:lakiite/presentation/calendar/edit_schedule_page.dart';
import 'package:lakiite/application/schedule/schedule_interaction_notifier.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/calendar/widgets/calendar_page_view.dart';
import 'package:lakiite/presentation/calendar/schedule_detail_page.dart';
import 'package:lakiite/presentation/widgets/ad_banner_widget.dart';

class CalendarPage extends HookConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final scheduleState = ref.watch(scheduleNotifierProvider);
    final initialized = useState(false);
    final userId = useState<String?>(null);
    final hideOwnSchedules = useState(false);

    useEffect(() {
      if (!authState.hasValue) return null;

      authState.whenData((state) {
        if (state.status == AuthStatus.authenticated && state.user != null) {
          final currentUserId = state.user!.id;

          if (!initialized.value || userId.value != currentUserId) {
            initialized.value = true;
            userId.value = currentUserId;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(scheduleNotifierProvider.notifier)
                  .watchUserSchedules(currentUserId);
              ref
                  .read(listNotifierProvider.notifier)
                  .watchUserLists(currentUserId);
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
                'スケジュール',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
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
                                    final filteredSchedules = hideOwnSchedules
                                            .value
                                        ? loaded.schedules
                                            .where((s) =>
                                                s.ownerId != state.user!.id)
                                            .toList()
                                        : loaded.schedules;

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
                                              padding: const EdgeInsets.only(
                                                  top: 4, bottom: 4),
                                              itemCount:
                                                  filteredSchedules.length,
                                              itemBuilder: (context, index) {
                                                final schedule =
                                                    filteredSchedules[index];
                                                return Card(
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16,
                                                      vertical: 6),
                                                  child: InkWell(
                                                    onTap: () {
                                                      Navigator.of(context)
                                                          .push(
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              ScheduleDetailPage(
                                                                  schedule:
                                                                      schedule),
                                                        ),
                                                      );
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16),
                                                      decoration: BoxDecoration(
                                                        border: schedule
                                                                    .ownerId ==
                                                                state.user!.id
                                                            ? Border.all(
                                                                color: Theme.of(
                                                                        context)
                                                                    .primaryColor
                                                                    .withOpacity(
                                                                        0.3),
                                                                width: 1,
                                                              )
                                                            : null,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        color: schedule
                                                                    .ownerId ==
                                                                state.user!.id
                                                            ? Theme.of(context)
                                                                .primaryColor
                                                                .withOpacity(
                                                                    0.05)
                                                            : null,
                                                      ),
                                                      child: _buildScheduleItem(
                                                          context,
                                                          schedule,
                                                          state.user!,
                                                          ref),
                                                    ),
                                                  ),
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
                          child: AdBannerWidget(),
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

  Widget _buildTimelineList(
    BuildContext context,
    List<Schedule> schedules,
    UserModel currentUser,
    WidgetRef ref,
  ) {
    final sortedSchedules = List<Schedule>.from(schedules)
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedSchedules.length,
      itemBuilder: (context, index) {
        final schedule = sortedSchedules[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ScheduleDetailPage(schedule: schedule),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: schedule.ownerId == currentUser.id
                    ? Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        width: 1,
                      )
                    : null,
                borderRadius: BorderRadius.circular(8),
                color: schedule.ownerId == currentUser.id
                    ? Theme.of(context).primaryColor.withOpacity(0.05)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          schedule.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (schedule.ownerId == currentUser.id)
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => EditSchedulePage(
                                  schedule: schedule,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<UserModel?>(
                    future: ref
                        .read(userRepositoryProvider)
                        .getUser(schedule.ownerId),
                    builder: (context, snapshot) {
                      final ownerName = snapshot.hasData
                          ? snapshot.data!.displayName
                          : '読み込み中...';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (schedule.description.isNotEmpty) ...[
                            Text(
                              schedule.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${DateFormat('yyyy/MM/dd HH:mm').format(schedule.startDateTime)} - '
                                  '${DateFormat('yyyy/MM/dd HH:mm').format(schedule.endDateTime)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (schedule.location != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    schedule.location!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '作成者: ${schedule.ownerId == currentUser.id ? '自分' : ownerName}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Consumer(
                            builder: (context, ref, _) {
                              final interactionState = ref.watch(
                                scheduleInteractionNotifierProvider(
                                    schedule.id),
                              );
                              if (interactionState.isLoading) {
                                return const SizedBox();
                              }
                              if (interactionState.error != null) {
                                return const SizedBox();
                              }
                              final reactionCounts =
                                  interactionState.reactionCounts;
                              final totalReactions = reactionCounts.values
                                  .fold(0, (sum, count) => sum + count);
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      if (interactionState.reactions.isNotEmpty)
                                        SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: Stack(
                                            children: [
                                              if (interactionState
                                                              .reactionCounts[
                                                          ReactionType
                                                              .thinking] !=
                                                      null &&
                                                  interactionState
                                                              .reactionCounts[
                                                          ReactionType
                                                              .thinking]! >
                                                      0)
                                                const Positioned(
                                                  right: 2,
                                                  child: Text(
                                                    '🤔',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                ),
                                              if (interactionState
                                                              .reactionCounts[
                                                          ReactionType.going] !=
                                                      null &&
                                                  interactionState
                                                              .reactionCounts[
                                                          ReactionType.going]! >
                                                      0)
                                                Positioned(
                                                  top: -1,
                                                  right: interactionState
                                                                      .reactionCounts[
                                                                  ReactionType
                                                                      .thinking] !=
                                                              null &&
                                                          interactionState
                                                                      .reactionCounts[
                                                                  ReactionType
                                                                      .thinking]! >
                                                              0
                                                      ? null
                                                      : 2,
                                                  left: interactionState
                                                                      .reactionCounts[
                                                                  ReactionType
                                                                      .thinking] !=
                                                              null &&
                                                          interactionState
                                                                      .reactionCounts[
                                                                  ReactionType
                                                                      .thinking]! >
                                                              0
                                                      ? -2
                                                      : null,
                                                  child: const Text(
                                                    '🙋',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        )
                                      else
                                        Icon(
                                          Icons.people,
                                          size: 16,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$totalReactions',
                                        style: TextStyle(
                                          color: interactionState
                                                  .reactions.isNotEmpty
                                              ? Colors.grey
                                              : Theme.of(context).primaryColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.comment,
                                    size: 16,
                                    color: Colors.blue[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${interactionState.commentCount}',
                                    style: TextStyle(
                                      color: Colors.blue[400],
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
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

  Widget _buildScheduleItem(
    BuildContext context,
    Schedule schedule,
    UserModel currentUser,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                schedule.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (schedule.ownerId == currentUser.id)
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Theme.of(context).primaryColor,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditSchedulePage(
                        schedule: schedule,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<UserModel?>(
          future: ref.read(userRepositoryProvider).getUser(schedule.ownerId),
          builder: (context, snapshot) {
            final ownerName =
                snapshot.hasData ? snapshot.data!.displayName : '読み込み中...';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (schedule.description.isNotEmpty) ...[
                  Text(
                    schedule.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${DateFormat('yyyy/MM/dd HH:mm').format(schedule.startDateTime)} - '
                        '${DateFormat('yyyy/MM/dd HH:mm').format(schedule.endDateTime)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                if (schedule.location != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          schedule.location!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '作成者: ${schedule.ownerId == currentUser.id ? '自分' : ownerName}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Consumer(
                  builder: (context, ref, _) {
                    final interactionState = ref.watch(
                      scheduleInteractionNotifierProvider(schedule.id),
                    );
                    if (interactionState.isLoading) {
                      return const SizedBox();
                    }
                    if (interactionState.error != null) {
                      return const SizedBox();
                    }
                    final reactionCounts = interactionState.reactionCounts;
                    final totalReactions = reactionCounts.values
                        .fold(0, (sum, count) => sum + count);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            if (interactionState.reactions.isNotEmpty)
                              SizedBox(
                                width: 30,
                                height: 30,
                                child: Stack(
                                  children: [
                                    if (interactionState.reactionCounts[
                                                ReactionType.thinking] !=
                                            null &&
                                        interactionState.reactionCounts[
                                                ReactionType.thinking]! >
                                            0)
                                      const Positioned(
                                        right: 2,
                                        child: Text(
                                          '🤔',
                                          style: TextStyle(
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                    if (interactionState.reactionCounts[
                                                ReactionType.going] !=
                                            null &&
                                        interactionState.reactionCounts[
                                                ReactionType.going]! >
                                            0)
                                      Positioned(
                                        top: -1,
                                        right: interactionState.reactionCounts[
                                                        ReactionType
                                                            .thinking] !=
                                                    null &&
                                                interactionState.reactionCounts[
                                                        ReactionType
                                                            .thinking]! >
                                                    0
                                            ? null
                                            : 2,
                                        left: interactionState.reactionCounts[
                                                        ReactionType
                                                            .thinking] !=
                                                    null &&
                                                interactionState.reactionCounts[
                                                        ReactionType
                                                            .thinking]! >
                                                    0
                                            ? -2
                                            : null,
                                        child: const Text(
                                          '🙋',
                                          style: TextStyle(
                                            fontSize: 20,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            else
                              Icon(
                                Icons.people,
                                size: 16,
                                color: Theme.of(context).primaryColor,
                              ),
                            const SizedBox(width: 4),
                            Text(
                              '$totalReactions',
                              style: TextStyle(
                                color: interactionState.reactions.isNotEmpty
                                    ? Colors.grey
                                    : Theme.of(context).primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.comment,
                          size: 16,
                          color: Colors.blue[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${interactionState.commentCount}',
                          style: TextStyle(
                            color: Colors.blue[400],
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
