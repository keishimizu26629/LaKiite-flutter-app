import 'package:lakiite/domain/interfaces/i_schedule_repository.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import '../base_mock.dart';

class MockScheduleRepository extends BaseMock implements IScheduleRepository {
  final List<Schedule> _schedules = [];
  bool _shouldFailSave = false;
  bool _shouldFailDelete = false;
  bool _shouldFailGet = false;

  void setShouldFailSave(bool shouldFail) {
    _shouldFailSave = shouldFail;
  }

  void setShouldFailDelete(bool shouldFail) {
    _shouldFailDelete = shouldFail;
  }

  void setShouldFailGet(bool shouldFail) {
    _shouldFailGet = shouldFail;
  }

  void addTestSchedule(Schedule schedule) {
    _schedules.add(schedule);
  }

  void clearSchedules() {
    _schedules.clear();
  }

  @override
  Future<List<Schedule>> getListSchedules(String listId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailGet) {
      throw Exception('テスト用取得失敗');
    }

    return _schedules.where((s) => s.sharedLists.contains(listId)).toList();
  }

  @override
  Future<List<Schedule>> getUserSchedules(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    if (_shouldFailGet) {
      throw Exception('テスト用取得失敗');
    }

    return _schedules.where((s) => s.ownerId == userId).toList();
  }

  @override
  Future<Schedule> createSchedule(Schedule schedule) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_shouldFailSave) {
      throw Exception('テスト用保存失敗');
    }

    final newSchedule = schedule.copyWith(
      id: 'generated-id-${_schedules.length}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _schedules.add(newSchedule);
    return newSchedule;
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (_shouldFailSave) {
      throw Exception('テスト用更新失敗');
    }

    final index = _schedules.indexWhere((s) => s.id == schedule.id);
    if (index >= 0) {
      _schedules[index] = schedule.copyWith(updatedAt: DateTime.now());
    } else {
      throw Exception('スケジュールが見つかりません');
    }
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    await Future.delayed(const Duration(milliseconds: 250));

    if (_shouldFailDelete) {
      throw Exception('テスト用削除失敗');
    }

    final initialLength = _schedules.length;
    _schedules.removeWhere((s) => s.id == scheduleId);

    if (_schedules.length == initialLength) {
      throw Exception('削除対象のスケジュールが見つかりません');
    }
  }

  @override
  Stream<List<Schedule>> watchListSchedules(String listId) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      return _schedules.where((s) => s.sharedLists.contains(listId)).toList();
    }).take(1);
  }

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      return _schedules.where((s) => s.ownerId == userId).toList();
    }).take(1);
  }

  @override
  Stream<List<Schedule>> watchUserSchedulesForMonth(
      String userId, DateTime displayMonth) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      return _schedules.where((s) {
        return s.ownerId == userId &&
            s.startDateTime.year == displayMonth.year &&
            s.startDateTime.month == displayMonth.month;
      }).toList();
    }).take(1);
  }

  @override
  Stream<Schedule?> watchSchedule(String scheduleId) {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      try {
        return _schedules.firstWhere((s) => s.id == scheduleId);
      } catch (e) {
        return null;
      }
    }).take(1);
  }

  /// テスト用のリセット機能
  void reset() {
    _schedules.clear();
    _shouldFailSave = false;
    _shouldFailDelete = false;
    _shouldFailGet = false;
  }
}
