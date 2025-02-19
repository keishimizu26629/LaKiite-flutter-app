import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lakiite/application/schedule/schedule_state.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/presentation/presentation_provider.dart';

part 'schedule_notifier.g.dart';

/// スケジュール状態を管理するNotifierクラス
@riverpod
class ScheduleNotifier extends AutoDisposeAsyncNotifier<ScheduleState> {
  // State management
  StreamSubscription<List<Schedule>>? _scheduleSubscription;
  String? _currentUserId;
  bool _isDisposed = false;

  @override
  Future<ScheduleState> build() async {
    _isDisposed = false;
    ref.onDispose(() {
      print('ScheduleNotifier: Disposing');
      _isDisposed = true;
      _scheduleSubscription?.cancel();
      _currentUserId = null;
    });
    return const ScheduleState.initial();
  }

  /// スケジュールを監視する
  ///
  /// [userId] 監視対象のユーザーID
  void watchUserSchedules(String userId) {
    if (_isDisposed) {
      print(
          'ScheduleNotifier: Notifier is disposed, ignoring watchUserSchedules');
      return;
    }

    print('ScheduleNotifier: watchUserSchedules called for user: $userId');

    // 同じユーザーの場合は重複購読を避ける
    if (_currentUserId == userId && _scheduleSubscription != null) {
      print('ScheduleNotifier: Already watching schedules for user: $userId');
      return;
    }

    // 既存の購読をキャンセル
    _scheduleSubscription?.cancel();
    _currentUserId = userId;

    try {
      print('ScheduleNotifier: Starting new subscription for user: $userId');
      final stream =
          ref.read(scheduleRepositoryProvider).watchUserSchedules(userId);

      _scheduleSubscription = stream.listen(
        (schedules) {
          if (_isDisposed) return;
          print('ScheduleNotifier: Received ${schedules.length} schedules');
          state = AsyncValue.data(ScheduleState.loaded(schedules));
        },
        onError: (error) {
          if (_isDisposed) return;
          print('ScheduleNotifier: Error watching schedules: $error');
          // エラーが発生しても既存のスケジュールは保持
          state = state.whenData((currentState) => currentState);
        },
      );
    } catch (e) {
      if (_isDisposed) return;
      print('ScheduleNotifier: Exception in watchUserSchedules: $e');
      state = AsyncValue.data(ScheduleState.error(e.toString()));
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
    if (_isDisposed) return;

    print('ScheduleNotifier: Creating new schedule...');
    print('Title: $title');
    print('Description: $description');
    print('StartDateTime: $startDateTime');
    print('EndDateTime: $endDateTime');
    print('OwnerId: $ownerId');
    print('SharedLists: $sharedLists');
    print('VisibleTo: $visibleTo');

    state = const AsyncValue.loading();
    try {
      // 作成者情報を取得
      final userDoc = await ref.read(userRepositoryProvider).getUser(ownerId);
      if (userDoc == null) {
        throw Exception('User not found');
      }

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
        createdAt: DateTime.now(), // リポジトリでサーバータイムスタンプに変換
        updatedAt: DateTime.now(), // リポジトリでサーバータイムスタンプに変換
      );
      print('ScheduleNotifier: Schedule object created, sending to repository...');

      final createdSchedule = await ref.read(scheduleRepositoryProvider).createSchedule(schedule);
      print('ScheduleNotifier: Schedule created successfully with ID: ${createdSchedule.id}');

      // 作成後にスケジュールを再読み込み
      if (_currentUserId != null) {
        watchUserSchedules(_currentUserId!);
      }
    } catch (e) {
      print('ScheduleNotifier: Error creating schedule: $e');
      if (_isDisposed) return;
      state = AsyncValue.data(ScheduleState.error(e.toString()));
    }
  }

  /// スケジュール情報を更新する
  Future<void> updateSchedule(Schedule schedule) async {
    if (_isDisposed) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(scheduleRepositoryProvider).updateSchedule(schedule);

      // 更新後にスケジュールを再読み込み
      if (_currentUserId != null) {
        watchUserSchedules(_currentUserId!);
      }
    } catch (e) {
      if (_isDisposed) return;
      state = AsyncValue.data(ScheduleState.error(e.toString()));
    }
  }

  /// スケジュールを削除する
  Future<void> deleteSchedule(String scheduleId) async {
    if (_isDisposed) return;

    state = const AsyncValue.loading();
    try {
      await ref.read(scheduleRepositoryProvider).deleteSchedule(scheduleId);

      // 削除後にスケジュールを再読み込み
      if (_currentUserId != null) {
        watchUserSchedules(_currentUserId!);
      }
    } catch (e) {
      if (_isDisposed) return;
      state = AsyncValue.data(ScheduleState.error(e.toString()));
    }
  }

  /// 特定のスケジュールを監視する
  Stream<Schedule?> watchSchedule(String scheduleId) {
    return ref.read(scheduleRepositoryProvider).watchSchedule(scheduleId);
  }
}
