import 'package:freezed_annotation/freezed_annotation.dart';

part 'list.freezed.dart';
part 'list.g.dart';

/// プライベートリスト情報を表現するモデルクラス
///
/// アプリケーション内での非公開のユーザーリストを管理します。
/// [freezed]パッケージを使用して、イミュータブルなデータ構造を実現します。
///
/// 主な情報:
/// - リストID
/// - リスト名
/// - オーナーID
/// - メンバーリスト（非公開）
/// - 作成日時
/// - アイコンURL（任意）
/// - リストの説明（任意）
@freezed
class UserList with _$UserList {
  /// UserListのコンストラクタ
  ///
  /// [id] リストの一意識別子
  /// [listName] リストの表示名
  /// [ownerId] リスト作成者のユーザーID
  /// [memberIds] リストに含まれるユーザーIDリスト（非公開）
  /// [createdAt] リストの作成日時
  /// [iconUrl] リストのアイコン画像URL（任意）
  /// [description] リストの説明文（任意）
  factory UserList({
    required String id,
    required String listName,
    required String ownerId,
    required List<String> memberIds,
    required DateTime createdAt,
    String? iconUrl,
    String? description,
  }) = _UserList;

  /// JSONからUserListを生成するファクトリーメソッド
  ///
  /// [json] リスト情報を含むJSON Map
  ///
  /// 返値: JSONから生成された[UserList]インスタンス
  factory UserList.fromJson(Map<String, dynamic> json) => _$UserListFromJson(json);
}
