import 'package:lakiite/domain/entity/list.dart';

/// プライベートリスト管理機能を提供するリポジトリのインターフェース
///
/// アプリケーションのプライベートリストに関する以下の機能を定義します:
/// - リストの取得・作成・更新・削除
/// - リストメンバーの追加・削除（非公開・通知なし）
/// - リスト情報の監視
///
/// このインターフェースの実装クラスは、
/// データストア(例:Firestore)とアプリケーションを
/// 橋渡しする役割を果たします。
abstract class IListRepository {
  /// ユーザーの全てのリストを取得する
  ///
  /// [ownerId] リストの所有者ID
  /// 返値: リストのリスト
  Future<List<UserList>> getLists(String ownerId);

  /// 新しいリストを作成する
  ///
  /// [listName] リストの名前
  /// [memberIds] 初期メンバーのユーザーIDリスト
  /// [ownerId] リスト作成者のユーザーID
  /// [iconUrl] リストのアイコン画像URL（任意）
  /// [description] リストの説明文（任意）
  ///
  /// 返値: 作成されたリスト情報
  Future<UserList> createList({
    required String listName,
    required List<String> memberIds,
    required String ownerId,
    String? iconUrl,
    String? description,
  });

  /// リスト情報を更新する
  ///
  /// [list] 更新するリスト情報
  Future<void> updateList(UserList list);

  /// リストを削除する
  ///
  /// [listId] 削除するリストのID
  Future<void> deleteList(String listId);

  /// リストにメンバーを追加する（非公開・通知なし）
  ///
  /// [listId] メンバーを追加するリストのID
  /// [userId] 追加するユーザーのID
  Future<void> addMember(String listId, String userId);

  /// リストからメンバーを削除する
  ///
  /// [listId] メンバーを削除するリストのID
  /// [userId] 削除するユーザーのID
  Future<void> removeMember(String listId, String userId);

  /// ユーザーの作成したリストを監視する
  ///
  /// [ownerId] 監視対象のユーザーID
  ///
  /// 返値: リストの変更を通知するStream
  Stream<List<UserList>> watchUserLists(String ownerId);

  /// 特定のリストを監視する
  ///
  /// [listId] 監視対象のリストID
  ///
  /// 返値: リストの変更を通知するStream
  Stream<UserList?> watchList(String listId);
}
