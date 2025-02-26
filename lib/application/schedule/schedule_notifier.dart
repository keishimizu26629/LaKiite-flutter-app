import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lakiite/application/schedule/schedule_state.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/utils/logger.dart';

part 'schedule_notifier.g.dart';

/// スケジュール状態を管理するNotifierクラス
@riverpod
class ScheduleNotifier extends AutoDisposeAsyncNotifier<ScheduleState> {
  // State management
  StreamSubscription<List<Schedule>>? _scheduleSubscription;
  String? _currentUserId;
  DateTime? _currentDisplayMonth;
  bool _isDisposed = false;

  @override
  Future<ScheduleState> build() async {
    _isDisposed = false;
    ref.onDispose(() {
      AppLogger.debug('ScheduleNotifier: Disposing');
      _isDisposed = true;
      _scheduleSubscription?.cancel();
      _currentUserId = null;
    });

    // 認証状態を監視して自動的にスケジュールの監視を開始
    ref.listen(authNotifierProvider, (previous, next) {
      next.whenData((authState) {
        if (authState.user != null) {
          watchUserSchedules(authState.user!.id);
        }
      });
    });

    return const ScheduleState.initial();
  }

  /// スケジュールを監視する
  ///
  /// [userId] 監視対象のユーザーID
  void watchUserSchedules(String userId) {
    if (_isDisposed) {
      AppLogger.debug(
          'ScheduleNotifier: Notifier is disposed, ignoring watchUserSchedules');
      return;
    }

    AppLogger.debug(
        'ScheduleNotifier: watchUserSchedules called for user: $userId');

    // 同じユーザーの場合は重複購読を避ける
    if (_currentUserId == userId && _scheduleSubscription != null) {
      AppLogger.debug(
          'ScheduleNotifier: Already watching schedules for user: $userId');
      return;
    }

    // 既存の購読をキャンセル
    _scheduleSubscription?.cancel();
    _currentUserId = userId;

    try {
      AppLogger.debug(
          'ScheduleNotifier: Starting new subscription for user: $userId');

      // ローディング状態を設定
      if (!_isDisposed) {
        state = const AsyncValue.loading();
      }

      final stream =
          ref.read(scheduleRepositoryProvider).watchUserSchedules(userId);

      _scheduleSubscription = stream.listen(
        (schedules) {
          if (_isDisposed) return;
          AppLogger.debug(
              'ScheduleNotifier: Received ${schedules.length} schedules');
          if (!_isDisposed) {
            state = AsyncValue.data(ScheduleState.loaded(schedules));
          }
        },
        onError: (error) {
          if (_isDisposed) return;
          AppLogger.error('ScheduleNotifier: Error watching schedules: $error');
          Future(() {
            if (!_isDisposed) {
              state = AsyncValue.error(error, StackTrace.current);
            }
          });
        },
      );
    } catch (e) {
      if (_isDisposed) return;
      AppLogger.error('ScheduleNotifier: Exception in watchUserSchedules: $e');
      Future(() {
        if (!_isDisposed) {
          state = AsyncValue.error(e, StackTrace.current);
        }
      });
    }
  }

  /// 表示月に基づいてスケジュールを監視する
  ///
  /// [userId] 監視対象のユーザーID
  /// [displayMonth] 表示中の月
  void watchUserSchedulesForMonth(String userId, DateTime displayMonth) {
    if (_isDisposed) {
      AppLogger.debug(
          'ScheduleNotifier: Notifier is disposed, ignoring watchUserSchedulesForMonth');
      return;
    }

    // 年月のみを比較するために正規化した日付を作成
    final normalizedDisplayMonth =
        DateTime(displayMonth.year, displayMonth.month, 1);

    AppLogger.debug(
        'ScheduleNotifier: watchUserSchedulesForMonth called for user: $userId, month: ${normalizedDisplayMonth.year}-${normalizedDisplayMonth.month}');

    // 同じユーザーかつ同じ月の場合は重複購読を避ける
    if (_currentUserId == userId && _currentDisplayMonth != null) {
      // 年月のみを比較
      final normalizedCurrentMonth =
          DateTime(_currentDisplayMonth!.year, _currentDisplayMonth!.month, 1);
      if (normalizedCurrentMonth.year == normalizedDisplayMonth.year &&
          normalizedCurrentMonth.month == normalizedDisplayMonth.month &&
          _scheduleSubscription != null) {
        AppLogger.debug(
            'ScheduleNotifier: Already watching schedules for user: $userId and month: ${normalizedDisplayMonth.year}-${normalizedDisplayMonth.month}');
        return;
      }
    }

    // 既存の購読をキャンセル
    _scheduleSubscription?.cancel();
    _currentUserId = userId;
    _currentDisplayMonth = normalizedDisplayMonth;

    try {
      AppLogger.debug(
          'ScheduleNotifier: Starting new subscription for user: $userId and month: ${normalizedDisplayMonth.year}-${normalizedDisplayMonth.month}');

      // ローディング状態を設定する前に現在のデータを保存
      // 注意: AsyncValueのisLoadingフラグを使用するため、
      // ローディング状態を明示的に設定しない

      final stream = ref
          .read(scheduleRepositoryProvider)
          .watchUserSchedulesForMonth(userId, normalizedDisplayMonth);

      _scheduleSubscription = stream.listen(
        (schedules) {
          if (_isDisposed) return;
          AppLogger.debug(
              'ScheduleNotifier: Received ${schedules.length} schedules for month: ${normalizedDisplayMonth.year}-${normalizedDisplayMonth.month}');
          if (!_isDisposed) {
            state = AsyncValue.data(ScheduleState.loaded(schedules));
          }
        },
        onError: (error) {
          if (_isDisposed) return;
          AppLogger.error(
              'ScheduleNotifier: Error watching schedules for month: $error');
          Future(() {
            if (!_isDisposed) {
              state = AsyncValue.error(error, StackTrace.current);
            }
          });
        },
      );
    } catch (e) {
      if (_isDisposed) return;
      AppLogger.error(
          'ScheduleNotifier: Exception in watchUserSchedulesForMonth: $e');
      Future(() {
        if (!_isDisposed) {
          state = AsyncValue.error(e, StackTrace.current);
        }
      });
    }
  }

  /// 新しいスケジュールを作成する
  Future<void> createSchedule({
    required String title,
    required String description,
    String? location,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required String ownerId,
    required List<String> sharedLists,
    required List<String> visibleTo,
  }) async {
    if (_isDisposed) {
      AppLogger.warning(
          'ScheduleNotifier: Attempted to create schedule after disposal');
      return;
    }

    AppLogger.debug('ScheduleNotifier: Starting schedule creation process');
    AppLogger.debug('Input parameters:');
    AppLogger.debug('Title: $title');
    AppLogger.debug('Description: $description');
    AppLogger.debug('Location: $location');
    AppLogger.debug('StartDateTime: $startDateTime');
    AppLogger.debug('EndDateTime: $endDateTime');
    AppLogger.debug('OwnerId: $ownerId');
    AppLogger.debug('SharedLists: $sharedLists');
    AppLogger.debug('VisibleTo: $visibleTo');

    try {
      AppLogger.debug('ScheduleNotifier: Fetching user information');
      final userDoc = await ref.read(userRepositoryProvider).getUser(ownerId);
      if (userDoc == null) {
        AppLogger.error('ScheduleNotifier: User not found for ID: $ownerId');
        throw Exception('User not found');
      }
      AppLogger.debug('ScheduleNotifier: User found - ${userDoc.displayName}');

      AppLogger.debug('ScheduleNotifier: Creating Schedule object');
      final schedule = Schedule(
        id: '', // Firestoreが自動生成
        title: title,
        description: description,
        location: location,
        startDateTime: startDateTime,
        endDateTime: endDateTime,
        ownerId: ownerId,
        ownerDisplayName: userDoc.displayName,
        ownerPhotoUrl: userDoc.iconUrl,
        sharedLists: sharedLists,
        visibleTo: visibleTo,
        reactionCount: 0,
        commentCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      AppLogger.debug('ScheduleNotifier: Sending schedule to repository');
      await ref.read(scheduleRepositoryProvider).createSchedule(schedule);
      AppLogger.debug('ScheduleNotifier: Schedule creation completed');

      // 作成完了後は自動的にストリームが更新を検知するため、
      // 明示的な再読み込みは不要
    } catch (e, stackTrace) {
      AppLogger.error(
          'ScheduleNotifier: Error in schedule creation', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// スケジュール情報を更新する
  Future<void> updateSchedule(Schedule schedule) async {
    if (_isDisposed) return;

    try {
      await ref.read(scheduleRepositoryProvider).updateSchedule(schedule);
      // 更新完了後は自動的にストリームが更新を検知するため、
      // 明示的な再読み込みは不要
    } catch (e, stackTrace) {
      AppLogger.error(
          'ScheduleNotifier: Error updating schedule', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// スケジュールを削除する
  Future<void> deleteSchedule(String scheduleId) async {
    if (_isDisposed) return;

    try {
      await ref.read(scheduleRepositoryProvider).deleteSchedule(scheduleId);
      // 削除完了後は自動的にストリームが更新を検知するため、
      // 明示的な再読み込みは不要
    } catch (e, stackTrace) {
      AppLogger.error(
          'ScheduleNotifier: Error deleting schedule', e, stackTrace);
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// 特定のスケジュールを監視する
  Stream<Schedule?> watchSchedule(String scheduleId) {
    return ref.read(scheduleRepositoryProvider).watchSchedule(scheduleId);
  }
}
