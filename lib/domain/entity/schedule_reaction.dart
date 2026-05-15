import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakiite/utils/logger.dart';

part 'schedule_reaction.freezed.dart';
part 'schedule_reaction.g.dart';

enum ReactionType {
  @JsonValue('going')
  going, // 行きます！🙋
  @JsonValue('thinking')
  thinking, // 考え中！🤔
}

@freezed
@JsonSerializable()
class ScheduleReaction with _$ScheduleReaction {
  const factory ScheduleReaction({
    required String id,
    required String userId,
    required ReactionType type,
    required DateTime createdAt,
    String? userDisplayName,
    String? userPhotoUrl,
  }) = _ScheduleReaction;

  factory ScheduleReaction.fromJson(Map<String, dynamic> json) {
    final Object? createdAt = json['createdAt'];

    // デバッグ用ログ追加
    AppLogger.debug(
        'ScheduleReaction.fromJson: createdAt=$createdAt (${createdAt?.runtimeType})');
    AppLogger.debug('Full JSON: $json');

    if (createdAt == null) {
      // createdAtがnullの場合は現在時刻を使用
      AppLogger.debug('createdAt is null, using current time');
      return _$ScheduleReactionFromJson({
        ...json,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    String isoDateString;
    try {
      if (createdAt is DateTime) {
        AppLogger.debug('createdAt is DateTime');
        isoDateString = createdAt.toIso8601String();
      } else if (createdAt is Timestamp) {
        AppLogger.debug('createdAt is Timestamp');
        isoDateString = createdAt.toDate().toIso8601String();
      } else if (createdAt is String) {
        AppLogger.debug('createdAt is String');
        // すでに文字列形式の場合はそのまま使用
        isoDateString = createdAt;
      } else {
        AppLogger.debug('createdAt is unknown type: ${createdAt.runtimeType}');
        // 未知の型の場合は現在時刻を使用
        isoDateString = DateTime.now().toIso8601String();
      }
    } catch (e, stack) {
      AppLogger.error('Error processing createdAt: $e');
      AppLogger.error('Stack: $stack');
      // エラーが発生した場合は現在時刻を使用
      isoDateString = DateTime.now().toIso8601String();
    }

    final result = _$ScheduleReactionFromJson({
      ...json,
      'createdAt': isoDateString,
    });

    AppLogger.debug('Created ScheduleReaction: $result');
    return result;
  }
}
