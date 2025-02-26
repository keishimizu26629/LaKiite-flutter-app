import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entity/schedule.dart';

/// スケジュールのドメインモデルとFirestoreデータの変換を担当するマッパー
class ScheduleMapper {
  /// FirestoreのドキュメントからScheduleエンティティを生成
  static Schedule fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Schedule(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      location: data['location'] as String?,
      startDateTime: _parseDateTime(data['startDateTime']),
      endDateTime: _parseDateTime(data['endDateTime']),
      ownerId: data['ownerId'] as String,
      ownerDisplayName: data['ownerDisplayName'] as String,
      ownerPhotoUrl: data['ownerPhotoUrl'] as String?,
      sharedLists: List<String>.from(data['sharedLists'] as List? ?? []),
      visibleTo: List<String>.from(data['visibleTo'] as List? ?? []),
      reactionCount: data['reactionCount'] as int? ?? 0,
      commentCount: data['commentCount'] as int? ?? 0,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  /// 日時フィールドをパースする内部メソッド
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  /// ScheduleエンティティからFirestore用のデータに変換
  static Map<String, dynamic> toFirestore(Schedule schedule) {
    return {
      'title': schedule.title,
      'description': schedule.description,
      'location': schedule.location,
      'startDateTime': schedule.startDateTime.toIso8601String(),
      'endDateTime': schedule.endDateTime.toIso8601String(),
      'ownerId': schedule.ownerId,
      'ownerDisplayName': schedule.ownerDisplayName,
      'ownerPhotoUrl': schedule.ownerPhotoUrl,
      'sharedLists': schedule.sharedLists,
      'visibleTo': schedule.visibleTo,
      'reactionCount': schedule.reactionCount,
      'commentCount': schedule.commentCount,
      'createdAt': schedule.createdAt.toIso8601String(),
      'updatedAt': schedule.updatedAt.toIso8601String(),
    };
  }
}
