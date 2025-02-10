import 'package:tarakite/domain/entity/group.dart';

/// グループ管理機能を提供するリポジトリのインターフェース
///
/// アプリケーションのグループに関する以下の機能を定義します:
/// - グループの取得・作成・更新・削除
/// - グループメンバーの追加・削除
/// - グループ情報の監視
///
/// このインターフェースの実装クラスは、
/// データストア(例:Firestore)とアプリケーションを
/// 橋渡しする役割を果たします。
abstract class IGroupRepository {
  /// 全てのグループを取得する
  ///
  /// 返値: グループのリスト
  Future<List<Group>> getGroups();

  /// 新しいグループを作成する
  ///
  /// [groupName] グループの名前
  /// [memberIds] 初期メンバーのユーザーIDリスト
  /// [ownerId] グループ作成者のユーザーID
  ///
  /// 返値: 作成されたグループ情報
  Future<Group> createGroup({
    required String groupName,
    required List<String> memberIds,
    required String ownerId,
  });

  /// グループ情報を更新する
  ///
  /// [group] 更新するグループ情報
  Future<void> updateGroup(Group group);

  /// グループを削除する
  ///
  /// [groupId] 削除するグループのID
  Future<void> deleteGroup(String groupId);

  /// グループにメンバーを追加する
  ///
  /// [groupId] メンバーを追加するグループのID
  /// [userId] 追加するユーザーのID
  Future<void> addMember(String groupId, String userId);

  /// グループからメンバーを削除する
  ///
  /// [groupId] メンバーを削除するグループのID
  /// [userId] 削除するユーザーのID
  Future<void> removeMember(String groupId, String userId);

  /// 特定のユーザーが所属するグループを監視する
  ///
  /// [userId] 監視対象のユーザーID
  ///
  /// 返値: グループリストの変更を通知するStream
  Stream<List<Group>> watchUserGroups(String userId);
}
