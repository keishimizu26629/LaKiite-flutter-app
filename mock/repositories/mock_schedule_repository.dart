import 'package:lakiite/domain/interfaces/i_schedule_repository.dart';
import 'package:lakiite/domain/entity/schedule.dart';

class MockScheduleRepository implements IScheduleRepository {
  final List<Schedule> _schedules = [];
  bool _shouldFailCreate = false;
  bool _shouldFailUpdate = false;
  bool _shouldFailDelete = false;

  void setShouldFailCreate(bool shouldFail) {
    _shouldFailCreate = shouldFail;
  }

  void setShouldFailUpdate(bool shouldFail) {
    _shouldFailUpdate = shouldFail;
  }

  void setShouldFailDelete(bool shouldFail) {
    _shouldFailDelete = shouldFail;
  }

  void setupSampleSchedules() {
    _schedules.clear();
    _schedules.addAll([
      Schedule(
        id: 'sample-1',
        title: 'サンプルスケジュール1',
        description: 'サンプル説明1',
        startDateTime: DateTime.now().add(const Duration(hours: 1)),
        endDateTime: DateTime.now().add(const Duration(hours: 2)),
        ownerId: 'test-user-id',
        ownerDisplayName: 'テストユーザー',
        location: 'サンプル場所1',
        sharedLists: const [],
        visibleTo: const ['test-user-id'],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      ),
      Schedule(
        id: 'sample-2',
        title: 'サンプルスケジュール2',
        description: 'サンプル説明2',
        startDateTime: DateTime.now().add(const Duration(days: 1)),
        endDateTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
        ownerId: 'test-user-id',
        ownerDisplayName: 'テストユーザー',
        location: 'サンプル場所2',
        sharedLists: const [],
        visibleTo: const ['test-user-id'],
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        updatedAt: DateTime.now(),
      ),
    ]);
  }

  @override
  Future<List<Schedule>> getListSchedules(String listId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _schedules
        .where((schedule) => schedule.sharedLists.contains(listId))
        .toList();
  }

  @override
  Future<List<Schedule>> getUserSchedules(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _schedules.where((schedule) => schedule.ownerId == userId).toList();
  }

  Future<List<Schedule>> getSchedules(String userId) async {
    return getUserSchedules(userId);
  }

  Future<Schedule?> getSchedule(String scheduleId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _schedules.firstWhere(
      (schedule) => schedule.id == scheduleId,
      orElse: () => throw StateError('Schedule not found'),
    );
  }

  @override
  Future<Schedule> createSchedule(Schedule schedule) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_shouldFailCreate) {
      throw Exception('スケジュール作成に失敗しました');
    }

    _schedules.add(schedule);
    return schedule;
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_shouldFailUpdate) {
      throw Exception('スケジュール更新に失敗しました');
    }

    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index != -1) {
      _schedules[index] = schedule;
    }
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailDelete) {
      throw Exception('スケジュール削除に失敗しました');
    }

    _schedules.removeWhere((schedule) => schedule.id == scheduleId);
  }

  @override
  Stream<List<Schedule>> watchListSchedules(String listId) async* {
    yield _schedules
        .where((schedule) => schedule.sharedLists.contains(listId))
        .toList();
  }

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) async* {
    yield _schedules.where((schedule) => schedule.ownerId == userId).toList();
  }

  @override
  Stream<List<Schedule>> watchUserSchedulesForMonth(
      String userId, DateTime displayMonth) async* {
    final startOfMonth = DateTime(displayMonth.year, displayMonth.month, 1);
    final endOfMonth = DateTime(displayMonth.year, displayMonth.month + 1, 1);

    yield _schedules
        .where((schedule) =>
            schedule.ownerId == userId &&
            schedule.startDateTime.isAfter(startOfMonth) &&
            schedule.startDateTime.isBefore(endOfMonth))
        .toList();
  }

  Stream<List<Schedule>> watchSchedules(String userId) async* {
    yield _schedules.where((schedule) => schedule.ownerId == userId).toList();
  }

  @override
  Stream<Schedule?> watchSchedule(String scheduleId) async* {
    final schedule = _schedules.firstWhere(
      (s) => s.id == scheduleId,
      orElse: () => throw StateError('Schedule not found'),
    );
    yield schedule;
  }

  Future<List<Schedule>> getSchedulesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _schedules
        .where((schedule) =>
            schedule.ownerId == userId &&
            schedule.startDateTime.isAfter(startDate) &&
            schedule.startDateTime.isBefore(endDate))
        .toList();
  }

  Future<List<Schedule>> getSchedulesByDate(
      String userId, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _schedules
        .where((schedule) =>
            schedule.ownerId == userId &&
            schedule.startDateTime.isAfter(startOfDay) &&
            schedule.startDateTime.isBefore(endOfDay))
        .toList();
  }

  void clearSchedules() {
    _schedules.clear();
  }
}
