import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lakiite/application/schedule/schedule_state.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/presentation_provider.dart';

part 'schedule_notifier.g.dart';

/// スケジュール状態を管理するNotifierクラス
///
/// アプリケーション内でのスケジュール操作に関する以下の機能を提供します:
/// - スケジュールの作成・更新・削除
/// - グループ別のスケジュール取得
/// - ユーザー別のスケジュール監視
///
/// Riverpodの状態管理システムと統合され、
/// アプリケーション全体でスケジュール状態を共有します。
@riverpod
class ScheduleNotifier extends AutoDisposeAsyncNotifier<ScheduleState> {
  @override
  Future<ScheduleState> build() async {
    return const ScheduleState.initial();
  }

  /// 新しいスケジュールを作成する
  ///
  /// [title] スケジュールのタイトル
  /// [dateTime] スケジュールの日時
  /// [ownerId] スケジュール作成者のユーザーID
  /// [groupId] スケジュールが属するグループのID
  ///
  /// エラー発生時は[ScheduleState.error]を返します。
  Future<void> createSchedule({
    required String title,
    required DateTime dateTime,
    required String ownerId,
    required String groupId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(scheduleRepositoryProvider).createSchedule(
            title: title,
            dateTime: dateTime,
            ownerId: ownerId,
            groupId: groupId,
          );
      await fetchSchedules(groupId);
    } catch (e) {
      state = AsyncValue.data(ScheduleState.error(e.toString()));
    }
  }

  /// 指定されたグループのスケジュールを取得する
  ///
  /// [groupId] スケジュールを取得するグループのID
  ///
  /// 取得成功時は[ScheduleState.loaded]を、
  /// エラー発生時は[ScheduleState.error]を返します。
  Future<void> fetchSchedules(String groupId) async {
    state = const AsyncValue.loading();
    try {
      final schedules = await ref.read(scheduleRepositoryProvider).getSchedules(groupId);
      state = AsyncValue.data(ScheduleState.loaded(schedules));
    } catch (e) {
      state = AsyncValue.data(ScheduleState.error(e.toString()));
    }
  }

  /// スケジュール情報を更新する
  ///
  /// [schedule] 更新するスケジュール情報
  ///
  /// エラー発生時は[ScheduleState.error]を返します。
  Future<void> updateSchedule(Schedule schedule) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(scheduleRepositoryProvider).updateSchedule(schedule);
      await fetchSchedules(schedule.groupId);
    } catch (e) {
      state = AsyncValue.data(ScheduleState.error(e.toString()));
    }
  }

  /// スケジュールを削除する
  ///
  /// [scheduleId] 削除するスケジュールのID
  /// [groupId] スケジュールが属するグループのID
  ///
  /// エラー発生時は[ScheduleState.error]を返します。
  Future<void> deleteSchedule(String scheduleId, String groupId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(scheduleRepositoryProvider).deleteSchedule(scheduleId);
      await fetchSchedules(groupId);
    } catch (e) {
      state = AsyncValue.data(ScheduleState.error(e.toString()));
    }
  }

  /// 特定のグループのスケジュールを監視する
  ///
  /// [groupId] 監視対象のグループID
  ///
  /// スケジュールリストの変更を[ScheduleState.loaded]として通知し、
  /// エラー発生時は[ScheduleState.error]を返します。
  void watchGroupSchedules(String groupId) {
    ref.read(scheduleRepositoryProvider).watchGroupSchedules(groupId).listen(
      (schedules) {
        state = AsyncValue.data(ScheduleState.loaded(schedules));
      },
      onError: (error) {
        state = AsyncValue.data(ScheduleState.error(error.toString()));
      },
    );
  }

  /// 特定のユーザーのスケジュールを監視する
  ///
  /// [userId] 監視対象のユーザーID
  ///
  /// スケジュールリストの変更を[ScheduleState.loaded]として通知し、
  /// エラー発生時は[ScheduleState.error]を返します。
  void watchUserSchedules(String userId) {
    ref.read(scheduleRepositoryProvider).watchUserSchedules(userId).listen(
      (schedules) {
        state = AsyncValue.data(ScheduleState.loaded(schedules));
      },
      onError: (error) {
        state = AsyncValue.data(ScheduleState.error(error.toString()));
      },
    );
  }
}
