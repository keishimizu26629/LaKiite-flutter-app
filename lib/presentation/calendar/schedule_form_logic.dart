import 'package:flutter/material.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/schedule.dart';

/// 予定フォーム全体の検証結果。
class ScheduleFormValidationResult {
  const ScheduleFormValidationResult({
    required this.hasRequiredFields,
    required this.hasInvalidTimeRange,
  });

  /// タイトル・場所など保存に必要な項目が入力済みかどうか。
  final bool hasRequiredFields;

  /// 終了日時が開始日時より前かどうか。
  final bool hasInvalidTimeRange;

  /// 現在の入力値で保存できるかどうか。
  bool get canSave => hasRequiredFields && !hasInvalidTimeRange;
}

/// 予定フォームで使う入力値の組み立てと正規化を担う純粋ロジック。
///
/// Widgetは表示状態とユーザー操作に集中し、日時計算や保存値の正規化はこのクラスへ集約する。
class ScheduleFormLogic {
  const ScheduleFormLogic._();

  /// フォームの開始日時初期値を返す。
  static DateTime initialStartDate({
    required Schedule? schedule,
    required DateTime? initialDate,
    required DateTime now,
  }) {
    if (schedule != null) {
      return schedule.startDateTime;
    }

    if (initialDate != null) {
      return DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
        now.hour,
        now.minute,
      );
    }

    return now;
  }

  /// フォームの終了日時初期値を返す。
  static DateTime initialEndDate({
    required Schedule? schedule,
    required DateTime? initialDate,
    required DateTime now,
  }) {
    if (schedule != null) {
      return schedule.endDateTime;
    }

    if (initialDate != null) {
      return DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
        now.hour + 1,
        now.minute,
      );
    }

    return now.add(const Duration(hours: 1));
  }

  /// [DateTime] からフォーム表示用の [TimeOfDay] を作る。
  static TimeOfDay timeOf(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  /// 日付選択値と時刻選択値を保存用の [DateTime] に組み合わせる。
  static DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// 終了日時が開始日時より前かどうかを返す。
  static bool hasInvalidTimeRange({
    required DateTime startDate,
    required TimeOfDay startTime,
    required DateTime endDate,
    required TimeOfDay endTime,
  }) {
    final startDateTime = combineDateAndTime(startDate, startTime);
    final endDateTime = combineDateAndTime(endDate, endTime);
    return endDateTime.isBefore(startDateTime);
  }

  /// 編集対象の予定に紐づくリストだけをフォームの初期選択値として返す。
  static List<UserList> selectedListsForSchedule({
    required Schedule? schedule,
    required List<UserList> lists,
  }) {
    if (schedule == null) {
      return const [];
    }

    return lists
        .where((list) => schedule.sharedLists.contains(list.id))
        .toList();
  }

  /// 保存時にリストエンティティからIDだけを取り出す。
  static List<String> listIds(List<UserList> lists) {
    return lists.map((list) => list.id).toList();
  }

  /// 既存挙動に合わせて、空文字の場所だけnullとして扱う。
  static String? optionalLocation(String location) {
    if (location.isEmpty) {
      return null;
    }
    return location;
  }

  /// 保存に必要なテキスト項目が入力済みかどうかを返す。
  static bool hasRequiredScheduleFields({required String title}) {
    return title.trim().isNotEmpty;
  }

  /// 予定フォーム全体の保存可否に必要な検証結果を返す。
  static ScheduleFormValidationResult validateScheduleForm({
    required String title,
    required DateTime startDate,
    required TimeOfDay startTime,
    required DateTime endDate,
    required TimeOfDay endTime,
  }) {
    return ScheduleFormValidationResult(
      hasRequiredFields: hasRequiredScheduleFields(title: title),
      hasInvalidTimeRange: hasInvalidTimeRange(
        startDate: startDate,
        startTime: startTime,
        endDate: endDate,
        endTime: endTime,
      ),
    );
  }
}
