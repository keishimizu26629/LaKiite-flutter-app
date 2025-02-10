import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule.freezed.dart';
part 'schedule.g.dart';

/// スケジュール情報を表現するモデルクラス
///
/// グループ内での予定・スケジュール情報を管理します。
/// [freezed]パッケージを使用して、イミュータブルなデータ構造を実現します。
///
/// 主な情報:
/// - スケジュールID
/// - タイトル
/// - 予定日時
/// - 作成者情報
/// - 所属グループ情報
/// - タイムスタンプ情報(作成日時、更新日時)
@freezed
class Schedule with _$Schedule {
  /// Scheduleのコンストラクタ
  ///
  /// [id] スケジュールの一意識別子
  /// [title] スケジュールのタイトル
  /// [dateTime] 予定日時
  /// [ownerId] スケジュール作成者のユーザーID
  /// [groupId] スケジュールが属するグループのID
  /// [createdAt] スケジュールの作成日時
  /// [updatedAt] スケジュールの最終更新日時
  factory Schedule({
    required String id,
    required String title,
    required DateTime dateTime,
    required String ownerId,
    required String groupId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Schedule;

  /// JSONからScheduleを生成するファクトリーメソッド
  ///
  /// [json] スケジュール情報を含むJSON Map
  ///
  /// 返値: JSONから生成された[Schedule]インスタンス
  factory Schedule.fromJson(Map<String, dynamic> json) => _$ScheduleFromJson(json);
}
