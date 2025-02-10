import 'package:freezed_annotation/freezed_annotation.dart';
import '../value/user_id.dart';
import '../service/user_id_generator.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// ユーザー情報を表現するモデルクラス
///
/// アプリケーション内でのユーザー情報を管理します。
/// [freezed]パッケージを使用して、イミュータブルなデータ構造を実現します。
///
/// 主な情報:
/// - ユーザーID
/// - 名前情報(基本名前と表示名)
/// - 検索用ID
/// - フレンド情報
/// - 所属グループ情報
/// - アイコン画像URL
@freezed
@JsonSerializable(explicitToJson: true)
class UserModel with _$UserModel {
  const UserModel._();

  /// UserModelのコンストラクタ
  ///
  /// [id] ユーザーの一意識別子
  /// [name] ユーザーの基本名
  /// [displayName] ユーザーの表示名
  /// [searchId] ユーザー検索用のID
  /// [friends] フレンドのIDリスト
  /// [groups] 所属グループのIDリスト
  /// [iconUrl] プロフィール画像のURL(オプション)
  const factory UserModel({
    required String id,
    required String name,
    required String displayName,
    required UserId searchId,
    required List<String> friends,
    required List<String> groups,
    String? iconUrl,
  }) = _UserModel;

  /// JSONからUserModelを生成するファクトリーメソッド
  ///
  /// [json] ユーザー情報を含むJSON Map
  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  /// 新規ユーザーを作成するファクトリーメソッド
  ///
  /// 最小限の情報からユーザーモデルを作成します。
  /// [id] ユーザーの一意識別子
  /// [name] ユーザーの名前(基本名と表示名の初期値として使用)
  ///
  /// 以下のデフォルト値が設定されます:
  /// - displayName: nameと同じ値
  /// - searchId: 自動生成
  /// - friends: 空リスト
  /// - groups: 空リスト
  /// - iconUrl: null
  factory UserModel.create({
    required String id,
    required String name,
  }) {
    return UserModel(
      id: id,
      name: name,
      displayName: name,
      searchId: UserIdGenerator.generateUserId(),
      friends: const [],
      groups: const [],
      iconUrl: null,
    );
  }

  /// 文字列からUserIdを生成するJSON変換ヘルパーメソッド
  static UserId _searchIdFromJson(String value) => UserId(value);

  /// UserIdを文字列に変換するJSON変換ヘルパーメソッド
  static String _searchIdToJson(UserId userId) => userId.toString();
}
