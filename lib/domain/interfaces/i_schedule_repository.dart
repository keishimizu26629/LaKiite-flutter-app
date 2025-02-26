import 'package:lakiite/domain/entity/schedule.dart';

/// スケジュール管理機能を提供するリポジトリのインターフェース
///
/// アプリケーションのスケジュールに関する以下の機能を定義します:
/// - スケジュールの取得・作成・更新・削除
/// - リスト別のスケジュール監視
/// - ユーザー別のスケジュール監視
///
/// このインターフェースの実装クラスは、
/// データストア(例:Firestore)とアプリケーションを
/// 橋渡しする役割を果たします。
abstract class IScheduleRepository {
  /// 指定されたリストのスケジュールを取得する
  ///
  /// [listId] スケジュールを取得するリストのID
  ///
  /// 返値: スケジュールのリスト
  Future<List<Schedule>> getListSchedules(String listId);

  /// 特定のユーザーのスケジュールを取得する
  ///
  /// [userId] スケジュールを取得するユーザーのID
  ///
  /// 返値: スケジュールのリスト
  Future<List<Schedule>> getUserSchedules(String userId);

  /// 新しいスケジュールを作成する
  ///
  /// [schedule] 作成するスケジュール情報
  ///
  /// 返値: 作成されたスケジュール情報
  Future<Schedule> createSchedule(Schedule schedule);

  /// スケジュール情報を更新する
  ///
  /// [schedule] 更新するスケジュール情報
  Future<void> updateSchedule(Schedule schedule);

  /// スケジュールを削除する
  ///
  /// [scheduleId] 削除するスケジュールのID
  Future<void> deleteSchedule(String scheduleId);

  /// 特定のリストのスケジュールを監視する
  ///
  /// [listId] 監視対象のリストID
  ///
  /// 返値: リストのスケジュールリストの変更を通知するStream
  Stream<List<Schedule>> watchListSchedules(String listId);

  /// 特定のユーザーに関連するスケジュールを監視する
  ///
  /// [userId] 監視対象のユーザーID
  ///
  /// 返値: ユーザーに関連するスケジュールリストの変更を通知するStream
  Stream<List<Schedule>> watchUserSchedules(String userId);

  /// 特定のユーザーが所有するスケジュールのみを監視する
  ///
  /// [userId] 監視対象のユーザーID
  ///
  /// 返値: ユーザーが所有するスケジュールリストの変更を通知するStream
  Stream<List<Schedule>> watchUserOwnedSchedules(String userId);

  /// 特定のユーザーに公開されていて、特定のユーザーが所有するスケジュールを監視する
  ///
  /// [visibleToUserId] スケジュールが公開されているユーザーID
  /// [ownerId] スケジュールの所有者ID
  ///
  /// 返値: 条件に一致するスケジュールリストの変更を通知するStream
  Stream<List<Schedule>> watchVisibleAndOwnedSchedules(
      String visibleToUserId, String ownerId);

  /// 特定のスケジュールを監視する
  ///
  /// [scheduleId] 監視対象のスケジュールID
  ///
  /// 返値: スケジュールの変更を通知するStream
  Stream<Schedule?> watchSchedule(String scheduleId);
}
