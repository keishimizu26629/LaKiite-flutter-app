import 'package:freezed_annotation/freezed_annotation.dart';

part 'group.freezed.dart';
part 'group.g.dart';

/// グループ情報を表現するモデルクラス
///
/// アプリケーション内でのグループ情報を管理します。
/// [freezed]パッケージを使用して、イミュータブルなデータ構造を実現します。
///
/// 主な情報:
/// - グループID
/// - グループ名
/// - オーナーID
/// - メンバーリスト
/// - 作成日時
@freezed
class Group with _$Group {
  /// Groupのコンストラクタ
  ///
  /// [id] グループの一意識別子
  /// [groupName] グループの表示名
  /// [ownerId] グループ作成者のユーザーID
  /// [memberIds] グループメンバーのユーザーIDリスト
  /// [createdAt] グループの作成日時
  factory Group({
    required String id,
    required String groupName,
    required String ownerId,
    required List<String> memberIds,
    required DateTime createdAt,
  }) = _Group;

  /// JSONからGroupを生成するファクトリーメソッド
  ///
  /// [json] グループ情報を含むJSON Map
  ///
  /// 返値: JSONから生成された[Group]インスタンス
  factory Group.fromJson(Map<String, dynamic> json) => _$GroupFromJson(json);
}
