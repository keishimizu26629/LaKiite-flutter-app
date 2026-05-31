import 'package:lakiite/domain/entity/schedule.dart';

/// Firestore schedule queries for a displayed calendar month.
///
/// The calendar renders a fixed 6-week grid, including leading and trailing
/// days around the visible month.
class ScheduleMonthRange {
  const ScheduleMonthRange({
    required this.startInclusive,
    required this.endExclusive,
  });

  /// Builds the calendar query window for [displayMonth].
  factory ScheduleMonthRange.forDisplayMonth(DateTime displayMonth) {
    final firstDayOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final leadingDays = firstDayOfMonth.weekday % DateTime.daysPerWeek;
    final startInclusive = firstDayOfMonth.subtract(
      Duration(days: leadingDays),
    );

    return ScheduleMonthRange(
      startInclusive: startInclusive,
      endExclusive: startInclusive.add(const Duration(days: 42)),
    );
  }

  /// First day rendered in the 42-day calendar grid at midnight.
  final DateTime startInclusive;

  /// Day after the last rendered day in the 42-day calendar grid at midnight.
  final DateTime endExclusive;

  /// Firestore-compatible lower bound ISO string.
  String get startInclusiveIso => _toFirestoreIso(startInclusive);

  /// Firestore-compatible upper bound ISO string.
  String get endExclusiveIso => _toFirestoreIso(endExclusive);

  bool overlaps(Schedule schedule) {
    final scheduleStart = schedule.startDateTime;
    final scheduleEnd = schedule.endDateTime;

    return scheduleStart.isBefore(endExclusive) &&
        !scheduleEnd.isBefore(startInclusive);
  }

  static String _toFirestoreIso(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-${day}T00:00:00.000';
  }
}
