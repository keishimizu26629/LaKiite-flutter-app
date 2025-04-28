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

  // 月ごとにスケジュールデータをキャッシュ
  final Map<String, List<Schedule>> _monthlyScheduleCache = {};
  // 先行読み込み中かどうかを示すフラグ
  final Set<String> _preloadingMonths = {};

  // 月のキャッシュキーを生成
  String _getMonthKey(DateTime month) {
    return '${month.year}-${month.month.toString().padLeft(2, '0')}';
  }

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

  /// 表示月に基づいてスケジュールを監視する（最適化版）
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
    final monthKey = _getMonthKey(normalizedDisplayMonth);

    AppLogger.debug(
        'ScheduleNotifier: watchUserSchedulesForMonth called for user: $userId, month: $monthKey');

    // 同じユーザーかつ同じ月の場合は重複購読を避ける
    if (_currentUserId == userId && _currentDisplayMonth != null) {
      // 年月のみを比較
      final normalizedCurrentMonth =
          DateTime(_currentDisplayMonth!.year, _currentDisplayMonth!.month, 1);
      final currentMonthKey = _getMonthKey(normalizedCurrentMonth);

      if (currentMonthKey == monthKey && _scheduleSubscription != null) {
        AppLogger.debug(
            'ScheduleNotifier: Already watching schedules for user: $userId and month: $monthKey');

        // キャッシュがあればそれを即座に表示（状態は維持）
        if (_monthlyScheduleCache.containsKey(monthKey)) {
          final cachedSchedules = _monthlyScheduleCache[monthKey]!;
          if (!_isDisposed) {
            state = AsyncValue.data(ScheduleState.loaded(cachedSchedules));
          }
        }

        return;
      }
    }

    // キャッシュ済みの場合はキャッシュデータを即座に表示しつつバックグラウンドで更新
    if (_monthlyScheduleCache.containsKey(monthKey)) {
      final cachedSchedules = _monthlyScheduleCache[monthKey]!;
      if (!_isDisposed) {
        // キャッシュを表示（ローディング状態にはしない）
        state = AsyncValue.data(ScheduleState.loaded(cachedSchedules));
      }

      // バックグラウンドで更新（フラグだけ立てて終了）
      _scheduleSubscription?.cancel();
      _fetchMonthSchedules(userId, normalizedDisplayMonth, monthKey);
      _currentUserId = userId;
      _currentDisplayMonth = normalizedDisplayMonth;

      // 前後の月も事前読み込み
      _preloadAdjacentMonths(userId, normalizedDisplayMonth);

      return;
    }

    // 既存の購読をキャンセル
    _scheduleSubscription?.cancel();
    _currentUserId = userId;
    _currentDisplayMonth = normalizedDisplayMonth;

    // 新規に読み込み
    _fetchMonthSchedules(userId, normalizedDisplayMonth, monthKey);

    // 前後の月も事前読み込み
    _preloadAdjacentMonths(userId, normalizedDisplayMonth);
  }

  // 月のスケジュールを実際に取得する処理
  void _fetchMonthSchedules(String userId, DateTime month, String monthKey) {
    try {
      AppLogger.debug(
          'ScheduleNotifier: Starting new subscription for user: $userId and month: $monthKey');

      // ローディング状態を設定する前に現在のデータを保存
      if (!_monthlyScheduleCache.containsKey(monthKey)) {
        // まだキャッシュがない場合は読み込み中表示
        if (!_isDisposed) {
          state = const AsyncValue.loading();
        }
      }

      final stream = ref
          .read(scheduleRepositoryProvider)
          .watchUserSchedulesForMonth(userId, month);

      _scheduleSubscription = stream.listen(
        (schedules) {
          if (_isDisposed) return;
          AppLogger.debug(
              'ScheduleNotifier: Received ${schedules.length} schedules for month: $monthKey');

          // キャッシュを更新
          _monthlyScheduleCache[monthKey] = schedules;

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
      AppLogger.error('ScheduleNotifier: Exception in fetchMonthSchedules: $e');
      Future(() {
        if (!_isDisposed) {
          state = AsyncValue.error(e, StackTrace.current);
        }
      });
    }
  }

  // 隣接する月のスケジュールを事前読み込み
  void _preloadAdjacentMonths(String userId, DateTime month) {
    if (userId == null || _isDisposed) return;

    // 前後1ヶ月を事前読み込み
    final prevMonth = DateTime(month.year, month.month - 1, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);

    _preloadMonth(userId, prevMonth);
    _preloadMonth(userId, nextMonth);
  }

  // 特定の月のスケジュールを事前読み込み
  void _preloadMonth(String userId, DateTime month) {
    final monthKey = _getMonthKey(month);

    // すでに読み込み中または読み込み済みならスキップ
    if (_preloadingMonths.contains(monthKey) ||
        _monthlyScheduleCache.containsKey(monthKey)) {
      return;
    }

    _preloadingMonths.add(monthKey);

    try {
      AppLogger.debug('ScheduleNotifier: Preloading month: $monthKey');

      final stream = ref
          .read(scheduleRepositoryProvider)
          .watchUserSchedulesForMonth(userId, month);

      // バックグラウンドで読み込むだけなので、状態は更新しない
      StreamSubscription? subscription;

      subscription = stream.listen((schedules) {
        if (_isDisposed) {
          subscription?.cancel();
          return;
        }

        AppLogger.debug(
            'ScheduleNotifier: Preloaded ${schedules.length} schedules for month: $monthKey');

        // キャッシュを更新
        _monthlyScheduleCache[monthKey] = schedules;
        _preloadingMonths.remove(monthKey);

        // 用が済んだらキャンセル
        subscription?.cancel();
      }, onError: (error) {
        AppLogger.error(
            'ScheduleNotifier: Error preloading month $monthKey: $error');
        _preloadingMonths.remove(monthKey);
        subscription?.cancel();
      }, onDone: () {
        _preloadingMonths.remove(monthKey);
        subscription?.cancel();
      });

      // 10秒後にタイムアウト
      Future.delayed(const Duration(seconds: 10), () {
        if (_preloadingMonths.contains(monthKey)) {
          AppLogger.debug(
              'ScheduleNotifier: Preloading timeout for month: $monthKey');
          _preloadingMonths.remove(monthKey);
          subscription?.cancel();
        }
      });
    } catch (e) {
      AppLogger.error('ScheduleNotifier: Exception in preloadMonth: $e');
      _preloadingMonths.remove(monthKey);
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
