import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lakiite/application/list/list_state.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/presentation/presentation_provider.dart';

part 'list_notifier.g.dart';

/// プライベートリスト状態を管理するNotifierクラス
///
/// アプリケーション内でのプライベートリスト操作に関する以下の機能を提供します:
/// - リストの作成・更新・削除
/// - リストメンバーの追加・削除（非公開・通知なし）
/// - リスト情報の取得と監視
///
/// Riverpodの状態管理システムと統合され、
/// アプリケーション全体でリスト状態を共有します。
@riverpod
class ListNotifier extends AutoDisposeAsyncNotifier<ListState> {
  @override
  Future<ListState> build() async {
    return const ListState.initial();
  }

  /// 新しいプライベートリストを作成する
  ///
  /// [listName] リストの名前
  /// [memberIds] 初期メンバーのユーザーIDリスト
  /// [ownerId] リスト作成者のユーザーID
  /// [iconUrl] リストのアイコン画像URL（任意）
  /// [description] リストの説明文（任意）
  ///
  /// エラー発生時は[ListState.error]を返します。
  Future<void> createList({
    required String listName,
    required List<String> memberIds,
    required String ownerId,
    String? iconUrl,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(listRepositoryProvider).createList(
            listName: listName,
            memberIds: memberIds,
            ownerId: ownerId,
            iconUrl: iconUrl,
            description: description,
          );
      await fetchLists(ownerId);
    } catch (e) {
      state = AsyncValue.data(ListState.error(e.toString()));
    }
  }

  /// ユーザーの全てのリスト情報を取得する
  ///
  /// [ownerId] リストの所有者ID
  ///
  /// 取得成功時は[ListState.loaded]を、
  /// エラー発生時は[ListState.error]を返します。
  Future<void> fetchLists(String ownerId) async {
    state = const AsyncValue.loading();
    try {
      final lists = await ref.read(listRepositoryProvider).getLists(ownerId);
      state = AsyncValue.data(ListState.loaded(lists));
    } catch (e) {
      state = AsyncValue.data(ListState.error(e.toString()));
    }
  }

  /// リスト情報を更新する
  ///
  /// [list] 更新するリスト情報
  ///
  /// エラー発生時は[ListState.error]を返します。
  Future<void> updateList(UserList list) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(listRepositoryProvider).updateList(list);
      await fetchLists(list.ownerId);
    } catch (e) {
      state = AsyncValue.data(ListState.error(e.toString()));
    }
  }

  /// リストを削除する
  ///
  /// [listId] 削除するリストのID
  /// [ownerId] リストの所有者ID
  ///
  /// エラー発生時は[ListState.error]を返します。
  Future<void> deleteList(String listId, String ownerId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(listRepositoryProvider).deleteList(listId);
      await fetchLists(ownerId);
    } catch (e) {
      state = AsyncValue.data(ListState.error(e.toString()));
    }
  }

  /// リストにメンバーを追加する（非公開・通知なし）
  ///
  /// [listId] メンバーを追加するリストのID
  /// [userId] 追加するユーザーのID
  /// [ownerId] リストの所有者ID
  ///
  /// エラー発生時は[ListState.error]を返します。
  Future<void> addMember(String listId, String userId, String ownerId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(listRepositoryProvider).addMember(listId, userId);
      await fetchLists(ownerId);
    } catch (e) {
      state = AsyncValue.data(ListState.error(e.toString()));
    }
  }

  /// リストからメンバーを削除する
  ///
  /// [listId] メンバーを削除するリストのID
  /// [userId] 削除するユーザーのID
  /// [ownerId] リストの所有者ID
  ///
  /// エラー発生時は[ListState.error]を返します。
  Future<void> removeMember(String listId, String userId, String ownerId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(listRepositoryProvider).removeMember(listId, userId);
      await fetchLists(ownerId);
    } catch (e) {
      state = AsyncValue.data(ListState.error(e.toString()));
    }
  }

  /// ユーザーの作成したリストを監視する
  ///
  /// [ownerId] 監視対象のユーザーID
  ///
  /// リストの変更を[ListState.loaded]として通知し、
  /// エラー発生時は[ListState.error]を返します。
  void watchUserLists(String ownerId) {
    ref.read(listRepositoryProvider).watchUserLists(ownerId).listen(
      (lists) {
        state = AsyncValue.data(ListState.loaded(lists));
      },
      onError: (error) {
        state = AsyncValue.data(ListState.error(error.toString()));
      },
    );
  }
}
