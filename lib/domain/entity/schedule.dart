/// スケジュール情報を表現するモデルクラス
///
/// グループ内での予定・スケジュール情報を管理します。
///
/// 主な情報:
/// - スケジュールID
/// - タイトル
/// - 予定日時
/// - 作成者情報
/// - 所属グループ情報
/// - タイムスタンプ情報(作成日時、更新日時)
class Schedule {
  final String id;
  final String title;
  final DateTime dateTime;
  final String ownerId;
  final String groupId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Schedule({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.ownerId,
    required this.groupId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      title: json['title'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      ownerId: json['ownerId'] as String,
      groupId: json['groupId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dateTime': dateTime.toIso8601String(),
        'ownerId': ownerId,
        'groupId': groupId,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Schedule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          dateTime == other.dateTime &&
          ownerId == other.ownerId &&
          groupId == other.groupId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      dateTime.hashCode ^
      ownerId.hashCode ^
      groupId.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'Schedule(id: $id, title: $title, dateTime: $dateTime, ownerId: $ownerId, groupId: $groupId, createdAt: $createdAt, updatedAt: $updatedAt)';
}
