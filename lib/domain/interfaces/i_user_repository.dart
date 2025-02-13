import 'dart:typed_data';
import '../entity/user.dart';
import '../value/user_id.dart';

/// ユーザー管理機能を提供するリポジトリのインターフェース
///
/// アプリケーションのユーザーに関する以下の機能を定義します:
/// - ユーザー情報の取得・作成・更新・削除
/// - プロフィール画像の管理
/// - ユーザーID関連の操作
/// - ユーザー情報の監視
///
/// このインターフェースの実装クラスは、
/// データストア(例:Firestore)とアプリケーションを
/// 橋渡しする役割を果たします。
abstract class IUserRepository {
  /// 指定されたIDのユーザー情報を取得する
  ///
  /// [id] 取得するユーザーのID
  ///
  /// 返値: ユーザーが存在する場合は[UserModel]、存在しない場合はnull
  Future<UserModel?> getUser(String id);

  /// 友達の公開プロフィール情報のみを取得する
  ///
  /// [id] 取得する友達のユーザーID
  ///
  /// 返値: ユーザーが存在する場合は[PublicUserModel]、存在しない場合はnull
  Future<PublicUserModel?> getFriendPublicProfile(String id);

  /// 新規ユーザーを作成する
  ///
  /// [user] 作成するユーザー情報
  Future<void> createUser(UserModel user);

  /// ユーザー情報を更新する
  ///
  /// [user] 更新するユーザー情報
  Future<void> updateUser(UserModel user);

  /// ユーザーを削除する
  ///
  /// [id] 削除するユーザーのID
  Future<void> deleteUser(String id);

  /// ユーザーのプロフィール画像をアップロードする
  ///
  /// [userId] 画像を設定するユーザーのID
  /// [imageBytes] アップロードする画像データ
  ///
  /// 返値: アップロードされた画像のURL、失敗時はnull
  Future<String?> uploadUserIcon(String userId, Uint8List imageBytes);

  /// ユーザーのプロフィール画像を削除する
  ///
  /// [userId] 画像を削除するユーザーのID
  Future<void> deleteUserIcon(String userId);

  /// 指定されたユーザーIDが未使用かどうかを確認する
  ///
  /// [userId] 確認するユーザーID
  ///
  /// 返値: ユーザーIDが未使用の場合はtrue
  Future<bool> isUserIdUnique(UserId userId);

  /// 検索用IDでユーザーを検索する
  ///
  /// [userId] 検索するユーザーID
  ///
  /// 返値: 該当するユーザーが存在する場合は[SearchUserModel]、存在しない場合はnull
  Future<SearchUserModel?> findByUserId(UserId userId);

  /// ユーザー情報の変更を監視する
  ///
  /// [id] 監視対象のユーザーID
  ///
  /// ユーザーの公開プロフィール情報の変更を監視する
  ///
  /// [id] 監視対象のユーザーID
  ///
  /// 返値: 公開プロフィール情報の変更を通知するStream
  Stream<PublicUserModel?> watchPublicProfile(String id);

  /// ユーザーの非公開プロフィール情報の変更を監視する
  ///
  /// [id] 監視対象のユーザーID
  ///
  /// 返値: 非公開プロフィール情報の変更を通知するStream
  Stream<PrivateUserModel?> watchPrivateProfile(String id);

  /// ユーザー情報の変更を監視する
  ///
  /// [id] 監視対象のユーザーID
  ///
  /// 返値: ユーザー情報の変更を通知するStream
  Stream<UserModel?> watchUser(String id);

  /// 検索用IDの文字列でユーザーを検索する
  ///
  /// [searchId] 検索するユーザーの検索用ID文字列
  ///
  /// 返値: 該当するユーザーが存在する場合は[SearchUserModel]、存在しない場合はnull
  /// Note: 検索結果には公開情報のみが含まれます
  Future<SearchUserModel?> findBySearchId(String searchId);
}
