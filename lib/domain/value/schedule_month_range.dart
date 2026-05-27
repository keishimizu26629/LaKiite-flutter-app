/// Firestore schedule queries for a displayed calendar month.
///
/// The calendar renders leading and trailing days around the visible month, so
/// the query intentionally covers the previous month through the next month.
class ScheduleMonthRange {
  const ScheduleMonthRange({
    required this.startInclusive,
    required this.endExclusive,
  });

  /// Builds the calendar query window for [displayMonth].
  factory ScheduleMonthRange.forDisplayMonth(DateTime displayMonth) {
    return ScheduleMonthRange(
      startInclusive: DateTime(displayMonth.year, displayMonth.month - 1, 1),
      endExclusive: DateTime(displayMonth.year, displayMonth.month + 2, 1),
    );
  }

  /// First day of the previous month at midnight.
  final DateTime startInclusive;

  /// First day of the month after next at midnight.
  final DateTime endExclusive;

  /// Firestore-compatible lower bound ISO string.
  String get startInclusiveIso => _toFirestoreIso(startInclusive);

  /// Firestore-compatible upper bound ISO string.
  String get endExclusiveIso => _toFirestoreIso(endExclusive);

  static String _toFirestoreIso(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-${day}T00:00:00.000';
  }
}
