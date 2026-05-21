import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'schedule_reaction.dart';

part 'reaction.freezed.dart';
part 'reaction.g.dart';

@freezed

/// スケジュールに対するユーザーのリアクションを表すドメインモデル。
///
/// Firestore 上ではリアクション種別は文字列で保存されるが、domain では
/// [ReactionType] として扱うことで取り得る値を型で表現する。
@freezed
class Reaction with _$Reaction {
  const factory Reaction({
    required String id,
    required String scheduleId,
    required String userId,
    required ReactionType type,
    required String userDisplayName,
    String? userPhotoUrl,
    @TimestampConverter() required DateTime createdAt,
  }) = _Reaction;

  factory Reaction.fromJson(Map<String, dynamic> json) =>
      _$ReactionFromJson(json);
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) => timestamp.toDate();

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}
