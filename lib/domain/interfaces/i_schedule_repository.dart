import 'package:tarakite/domain/entity/schedule.dart';

/// スケジュール管理機能を提供するリポジトリのインターフェース
///
/// アプリケーションのスケジュールに関する以下の機能を定義します:
/// - スケジュールの取得・作成・更新・削除
/// - グループ別のスケジュール監視
/// - ユーザー別のスケジュール監視
///
/// このインターフェースの実装クラスは、
/// データストア(例:Firestore)とアプリケーションを
/// 橋渡しする役割を果たします。
abstract class IScheduleRepository {
  /// 指定されたグループのスケジュールを取得する
  ///
  /// [groupId] スケジュールを取得するグループのID
  ///
  /// 返値: スケジュールのリスト
  Future<List<Schedule>> getSchedules(String groupId);

  /// 新しいスケジュールを作成する
  ///
  /// [title] スケジュールのタイトル
  /// [dateTime] スケジュールの日時
  /// [ownerId] スケジュール作成者のユーザーID
  /// [groupId] スケジュールが属するグループのID
  ///
  /// 返値: 作成されたスケジュール情報
  Future<Schedule> createSchedule({
    required String title,
    required DateTime dateTime,
    required String ownerId,
    required String groupId,
  });

  /// スケジュール情報を更新する
  ///
  /// [schedule] 更新するスケジュール情報
  Future<void> updateSchedule(Schedule schedule);

  /// スケジュールを削除する
  ///
  /// [scheduleId] 削除するスケジュールのID
  Future<void> deleteSchedule(String scheduleId);

  /// 特定のグループのスケジュールを監視する
  ///
  /// [groupId] 監視対象のグループID
  ///
  /// 返値: グループのスケジュールリストの変更を通知するStream
  Stream<List<Schedule>> watchGroupSchedules(String groupId);

  /// 特定のユーザーに関連するスケジュールを監視する
  ///
  /// [userId] 監視対象のユーザーID
  ///
  /// 返値: ユーザーに関連するスケジュールリストの変更を通知するStream
  Stream<List<Schedule>> watchUserSchedules(String userId);
}
