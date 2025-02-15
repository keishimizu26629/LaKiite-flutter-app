import 'package:freezed_annotation/freezed_annotation.dart';

part 'schedule.freezed.dart';
part 'schedule.g.dart';

/// スケジュール情報を表現するモデルクラス
///
/// ユーザーの予定・スケジュール情報を管理します。
///
/// 主な情報:
/// - スケジュールID
/// - タイトル
/// - 説明
/// - 場所
/// - 予定日時
/// - 作成者情報
/// - 共有リスト情報
/// - 閲覧可能なユーザー情報
/// - タイムスタンプ情報(作成日時、更新日時)
@freezed
class Schedule with _$Schedule {
  const factory Schedule({
    required String id,
    required String title,
    required String description,
    String? location,
    required DateTime dateTime,
    required String ownerId,
    required List<String> sharedLists,
    required List<String> visibleTo,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Schedule;

  factory Schedule.fromJson(Map<String, dynamic> json) =>
      _$ScheduleFromJson(json);
}
