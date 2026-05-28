import 'package:lakiite/domain/entity/schedule.dart';

class ScheduleDisplayOrder {
  const ScheduleDisplayOrder._();

  static List<Schedule> sortedWithinDay(Iterable<Schedule> schedules) {
    return List<Schedule>.from(schedules)..sort(compareWithinDay);
  }

  static List<Schedule> sortedTimeline(Iterable<Schedule> schedules) {
    return List<Schedule>.from(schedules)..sort(compareTimeline);
  }

  static int compareTimeline(Schedule a, Schedule b) {
    final dateComparison = _dateOnly(
      a.startDateTime,
    ).compareTo(_dateOnly(b.startDateTime));
    if (dateComparison != 0) {
      return dateComparison;
    }

    return compareWithinDay(a, b);
  }

  static int compareWithinDay(Schedule a, Schedule b) {
    if (a.isAllDay != b.isAllDay) {
      return a.isAllDay ? -1 : 1;
    }

    if (a.isAllDay) {
      return a.createdAt.compareTo(b.createdAt);
    }

    final startComparison = a.startDateTime.compareTo(b.startDateTime);
    if (startComparison != 0) {
      return startComparison;
    }

    return a.createdAt.compareTo(b.createdAt);
  }

  static DateTime _dateOnly(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
