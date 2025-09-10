import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/logger.dart';

part 'schedule_comment.freezed.dart';
part 'schedule_comment.g.dart';

@freezed
@JsonSerializable()
class ScheduleComment with _$ScheduleComment {
  const factory ScheduleComment({
    required String id,
    required String userId,
    required String content,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(false) bool isEdited,
    String? userDisplayName,
    String? userPhotoUrl,
  }) = _ScheduleComment;

  factory ScheduleComment.fromJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    final isEdited = json['isEdited'] ?? false;

    // デバッグログを追加
    AppLogger.debug(
        'ScheduleComment.fromJson: createdAt=$createdAt, updatedAt=$updatedAt, isEdited=$isEdited, json=$json');

    try {
      final processedJson = {
        ...json,
        'createdAt': createdAt is DateTime
            ? createdAt.toIso8601String()
            : (createdAt as Timestamp).toDate().toIso8601String(),
        'updatedAt': updatedAt == null
            ? null
            : updatedAt is DateTime
                ? updatedAt.toIso8601String()
                : (updatedAt as Timestamp).toDate().toIso8601String(),
        'isEdited': isEdited,
      };

      // 変換後のJSONをログ出力
      AppLogger.debug('Processed JSON: $processedJson');

      return _$ScheduleCommentFromJson(processedJson);
    } catch (e) {
      AppLogger.error('ScheduleComment.fromJson error: $e');
      // エラー時のフォールバック - 最低限必要なフィールドのみで構築
      return ScheduleComment(
        id: json['id'] as String,
        userId: json['userId'] as String,
        content: json['content'] as String,
        createdAt: createdAt is DateTime
            ? createdAt
            : (createdAt as Timestamp).toDate(),
        updatedAt: updatedAt == null
            ? null
            : updatedAt is DateTime
                ? updatedAt
                : (updatedAt as Timestamp).toDate(),
        isEdited: isEdited,
        userDisplayName: json['userDisplayName'] as String?,
        userPhotoUrl: json['userPhotoUrl'] as String?,
      );
    }
  }
}
