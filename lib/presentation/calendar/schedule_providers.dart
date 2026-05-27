import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/entity/schedule.dart';

/// Request parameters for calendar month schedule streams.
typedef CalendarMonthSchedulesQuery = ({
  String userId,
  DateTime displayMonth,
});

/// User schedule list read model for calendar and profile presentation UIs.
///
/// This provider is presentation read state. Schedule mutations and monthly
/// loading remain owned by the application schedule notifier.
final userSchedulesStreamProvider =
    StreamProvider.family<List<Schedule>, String>((ref, userId) {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (state) {
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value([]);
      }

      return ref.watch(scheduleRepositoryProvider).watchUserSchedules(userId);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Calendar-specific schedule read model for a displayed month.
///
/// Calendar rendering reads schedules directly from the repository so it does
/// not replace or cancel the timeline/global subscription owned by
/// `scheduleNotifierProvider`.
final calendarMonthSchedulesProvider =
    StreamProvider.family<List<Schedule>, CalendarMonthSchedulesQuery>(
  (ref, query) {
    final authState = ref.watch(authNotifierProvider);
    final displayMonth = DateTime(
      query.displayMonth.year,
      query.displayMonth.month,
      1,
    );

    return authState.when(
      data: (state) {
        if (state.status != AuthStatus.authenticated ||
            state.user?.id != query.userId) {
          return Stream.value([]);
        }

        return ref
            .watch(scheduleRepositoryProvider)
            .watchUserSchedulesForMonth(query.userId, displayMonth);
      },
      loading: () => Stream.value([]),
      error: (_, __) => Stream.value([]),
    );
  },
);
