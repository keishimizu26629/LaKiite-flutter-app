import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/interfaces/i_schedule_repository.dart';
import 'package:lakiite/domain/interfaces/i_friend_list_repository.dart';
import 'package:lakiite/domain/interfaces/i_user_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';
import 'package:lakiite/utils/logger.dart';

/// スケジュール関連のビジネスロジックを集約するManager
///
/// 責務:
/// - スケジュール作成時のビジネスルール適用
/// - 可視対象ユーザーの計算
/// - スケジュールのエンリッチメント（リアクション数・コメント数）
/// - バリデーション
abstract class IScheduleManager {
  /// スケジュールを作成する
  ///
  /// ビジネスルール:
  /// 1. 共有リストのメンバーを可視対象に追加
  /// 2. ユーザー情報（表示名、アイコン）を取得して設定
  /// 3. 作成日時・更新日時を設定
  ///
  /// [schedule] 作成するスケジュール（idは空文字列）
  /// 返値: 作成されたスケジュール（idが設定されている）
  /// 例外: ValidationException - バリデーションエラー
  ///       UserNotFoundException - ユーザーが見つからない
  Future<Schedule> createSchedule(Schedule schedule);

  /// スケジュールを更新する
  ///
  /// ビジネスルール:
  /// 1. 共有リストのメンバーを可視対象に追加
  /// 2. 更新日時を設定
  ///
  /// [schedule] 更新するスケジュール
  /// 例外: ValidationException - バリデーションエラー
  ///       ScheduleNotFoundException - スケジュールが見つからない
  Future<void> updateSchedule(Schedule schedule);

  /// スケジュールを削除する
  ///
  /// [scheduleId] 削除するスケジュールのID
  /// 例外: ScheduleNotFoundException - スケジュールが見つからない
  Future<void> deleteSchedule(String scheduleId);

  /// スケジュールにインタラクション情報を付加する
  ///
  /// [schedule] エンリッチメント対象のスケジュール
  /// 返値: リアクション数・コメント数が設定されたスケジュール
  Future<Schedule> enrichScheduleWithInteractions(Schedule schedule);

  /// ユーザーのスケジュールを監視する
  ///
  /// [userId] 監視対象のユーザーID
  /// 返値: スケジュールのリストを通知するStream（エンリッチメント済み）
  Stream<List<Schedule>> watchUserSchedules(String userId);

  /// 特定月のユーザースケジュールを監視する
  ///
  /// [userId] 監視対象のユーザーID
  /// [displayMonth] 表示月
  /// 返値: スケジュールのリストを通知するStream（エンリッチメント済み）
  Stream<List<Schedule>> watchUserSchedulesForMonth(
    String userId,
    DateTime displayMonth,
  );

  /// 特定のスケジュールを監視する
  ///
  /// [scheduleId] 監視対象のスケジュールID
  /// 返値: スケジュールを通知するStream（エンリッチメント済み）
  Stream<Schedule?> watchSchedule(String scheduleId);
}

/// ScheduleManagerの実装
class ScheduleManager implements IScheduleManager {
  ScheduleManager(
    this._scheduleRepository,
    this._friendListRepository,
    this._userRepository,
    this._interactionRepository,
  );
  final IScheduleRepository _scheduleRepository;
  final IFriendListRepository _friendListRepository;
  final IUserRepository _userRepository;
  final IScheduleInteractionRepository _interactionRepository;

  @override
  Future<Schedule> createSchedule(Schedule schedule) async {
    AppLogger.debug('ScheduleManager: Creating schedule - ${schedule.title}');

    // バリデーション
    _validateSchedule(schedule);

    // ユーザー情報を取得
    final user = await _userRepository.getUser(schedule.ownerId);
    if (user == null) {
      AppLogger.error('ScheduleManager: User not found - ${schedule.ownerId}');
      throw UserNotFoundException(schedule.ownerId);
    }

    // 可視対象ユーザーを計算
    final visibleTo = await _calculateVisibleUsers(schedule);

    // スケジュールを完全な状態にする
    final now = DateTime.now();
    final enrichedSchedule = schedule.copyWith(
      visibleTo: visibleTo,
      ownerDisplayName: user.displayName,
      ownerPhotoUrl: user.iconUrl,
      createdAt: now,
      updatedAt: now,
    );

    AppLogger.debug(
        'ScheduleManager: Visible users calculated - ${visibleTo.length} users');

    // リポジトリに保存
    final created = await _scheduleRepository.createSchedule(enrichedSchedule);

    AppLogger.info(
        'ScheduleManager: Schedule created successfully - ${created.id}');
    return created;
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    AppLogger.debug('ScheduleManager: Updating schedule - ${schedule.id}');

    // バリデーション
    _validateSchedule(schedule);

    // 可視対象ユーザーを計算
    final visibleTo = await _calculateVisibleUsers(schedule);

    // 更新日時を設定
    final updatedSchedule = schedule.copyWith(
      visibleTo: visibleTo,
      updatedAt: DateTime.now(),
    );

    // リポジトリに保存
    await _scheduleRepository.updateSchedule(updatedSchedule);

    AppLogger.info(
        'ScheduleManager: Schedule updated successfully - ${schedule.id}');
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    AppLogger.debug('ScheduleManager: Deleting schedule - $scheduleId');

    await _scheduleRepository.deleteSchedule(scheduleId);

    AppLogger.info(
        'ScheduleManager: Schedule deleted successfully - $scheduleId');
  }

  @override
  Future<Schedule> enrichScheduleWithInteractions(Schedule schedule) async {
    try {
      // リアクション数とコメント数を並列で取得
      final results = await Future.wait([
        _interactionRepository.getReactionCount(schedule.id),
        _interactionRepository.getCommentCount(schedule.id),
      ]);

      return schedule.copyWith(
        reactionCount: results[0],
        commentCount: results[1],
      );
    } catch (e) {
      AppLogger.error('ScheduleManager: Error enriching schedule - $e');
      // エラー時は元のスケジュールを返す
      return schedule;
    }
  }

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) async* {
    AppLogger.debug('ScheduleManager: Watching user schedules - $userId');

    await for (final schedules
        in _scheduleRepository.watchUserSchedules(userId)) {
      // エンリッチメント処理
      final enrichedSchedules = await _enrichScheduleList(schedules);
      yield enrichedSchedules;
    }
  }

  @override
  Stream<List<Schedule>> watchUserSchedulesForMonth(
    String userId,
    DateTime displayMonth,
  ) async* {
    AppLogger.debug(
        'ScheduleManager: Watching user schedules for month - $userId, ${displayMonth.year}-${displayMonth.month}');

    await for (final schedules in _scheduleRepository
        .watchUserSchedulesForMonth(userId, displayMonth)) {
      // エンリッチメント処理
      final enrichedSchedules = await _enrichScheduleList(schedules);
      yield enrichedSchedules;
    }
  }

  @override
  Stream<Schedule?> watchSchedule(String scheduleId) async* {
    AppLogger.debug('ScheduleManager: Watching schedule - $scheduleId');

    await for (final schedule
        in _scheduleRepository.watchSchedule(scheduleId)) {
      if (schedule == null) {
        yield null;
      } else {
        yield await enrichScheduleWithInteractions(schedule);
      }
    }
  }

  // ===== Private Methods =====

  /// スケジュールのバリデーション
  void _validateSchedule(Schedule schedule) {
    if (schedule.title.isEmpty) {
      throw ValidationException('タイトルは必須です');
    }

    if (schedule.startDateTime.isAfter(schedule.endDateTime)) {
      throw ValidationException('開始日時は終了日時より前である必要があります');
    }

    if (schedule.ownerId.isEmpty) {
      throw ValidationException('オーナーIDは必須です');
    }
  }

  /// 可視対象ユーザーを計算
  Future<List<String>> _calculateVisibleUsers(Schedule schedule) async {
    final Set<String> visibleTo = {...schedule.visibleTo};

    // 共有リストのメンバーを追加
    for (final listId in schedule.sharedLists) {
      try {
        final memberIds = await _friendListRepository.getListMemberIds(listId);
        if (memberIds != null) {
          visibleTo.addAll(memberIds);
          AppLogger.debug(
              'ScheduleManager: Added ${memberIds.length} members from list $listId');
        }
      } catch (e) {
        AppLogger.warning(
            'ScheduleManager: Error getting members for list $listId - $e');
        // エラーが発生しても処理を継続
      }
    }

    return visibleTo.toList();
  }

  /// スケジュールリストのエンリッチメント
  Future<List<Schedule>> _enrichScheduleList(List<Schedule> schedules) async {
    // バッチサイズを制限して並列処理
    const batchSize = 10;
    final enrichedSchedules = <Schedule>[];

    for (int i = 0; i < schedules.length; i += batchSize) {
      final end =
          (i + batchSize < schedules.length) ? i + batchSize : schedules.length;
      final batch = schedules.sublist(i, end);

      final enrichedBatch = await Future.wait(
        batch.map((schedule) => enrichScheduleWithInteractions(schedule)),
      );

      enrichedSchedules.addAll(enrichedBatch);
    }

    return enrichedSchedules;
  }
}

// ===== カスタム例外 =====

class ValidationException implements Exception {
  ValidationException(this.message);
  final String message;

  @override
  String toString() => 'ValidationException: $message';
}

class UserNotFoundException implements Exception {
  UserNotFoundException(this.userId);
  final String userId;

  @override
  String toString() => 'UserNotFoundException: User not found - $userId';
}

class ScheduleNotFoundException implements Exception {
  ScheduleNotFoundException(this.scheduleId);
  final String scheduleId;

  @override
  String toString() =>
      'ScheduleNotFoundException: Schedule not found - $scheduleId';
}
