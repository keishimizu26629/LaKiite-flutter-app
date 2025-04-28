import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final createdAt = json['createdAt'];

    // デバッグ用ログ追加
    print(
        'ScheduleReaction.fromJson: createdAt=$createdAt (${createdAt?.runtimeType})');
    print('Full JSON: $json');

    if (createdAt == null) {
      // createdAtがnullの場合は現在時刻を使用
      print('createdAt is null, using current time');
      return _$ScheduleReactionFromJson({
        ...json,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    String isoDateString;
    try {
      if (createdAt is DateTime) {
        print('createdAt is DateTime');
        isoDateString = createdAt.toIso8601String();
      } else if (createdAt is Timestamp) {
        print('createdAt is Timestamp');
        isoDateString = createdAt.toDate().toIso8601String();
      } else if (createdAt is String) {
        print('createdAt is String');
        // すでに文字列形式の場合はそのまま使用
        isoDateString = createdAt;
      } else {
        print('createdAt is unknown type: ${createdAt.runtimeType}');
        // 未知の型の場合は現在時刻を使用
        isoDateString = DateTime.now().toIso8601String();
      }
    } catch (e, stack) {
      print('Error processing createdAt: $e');
      print('Stack: $stack');
      // エラーが発生した場合は現在時刻を使用
      isoDateString = DateTime.now().toIso8601String();
    }

    final result = _$ScheduleReactionFromJson({
      ...json,
      'createdAt': isoDateString,
    });

    print('Created ScheduleReaction: $result');
    return result;
  }
}
