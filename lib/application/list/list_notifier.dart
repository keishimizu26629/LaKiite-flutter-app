import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:lakiite/application/list/list_state.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/service/service_provider.dart';

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
      final list = await ref.read(listManagerProvider).createList(
            userId: ownerId,
            listName: listName,
            memberIds: memberIds,
            description: description,
            iconUrl: iconUrl,
          );
      state = AsyncValue.data(ListState.loaded([list]));
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
      await ref.read(listManagerProvider).updateList(list);
      state = AsyncValue.data(ListState.loaded([list]));
    } catch (e) {
      state = AsyncValue.data(ListState.error(e.toString()));
    }
  }

  /// リストを削除する
  ///
  /// [listId] 削除するリストのID
  ///
  /// エラー発生時は[ListState.error]を返します。
  Future<void> deleteList(String listId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(listManagerProvider).deleteList(listId);
      state = const AsyncValue.data(ListState.loaded([]));
    } catch (e) {
      state = AsyncValue.data(ListState.error(e.toString()));
    }
  }

  /// リストにメンバーを追加する（非公開・通知なし）
  ///
  /// [listId] メンバーを追加するリストのID
  /// [userId] 追加するユーザーのID
  ///
  /// エラー発生時は[ListState.error]を返します。
  Future<void> addMember(String listId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(listManagerProvider).addMember(listId, userId);
      // 成功時の状態更新は要件に応じて実装
      state = const AsyncValue.data(ListState.loaded([]));
    } catch (e) {
      state = AsyncValue.data(ListState.error(e.toString()));
    }
  }

  /// リストからメンバーを削除する
  ///
  /// [listId] メンバーを削除するリストのID
  /// [userId] 削除するユーザーのID
  ///
  /// エラー発生時は[ListState.error]を返します。
  Future<void> removeMember(String listId, String userId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(listManagerProvider).removeMember(listId, userId);
      // 成功時の状態更新は要件に応じて実装
      state = const AsyncValue.data(ListState.loaded([]));
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
    ref.read(listManagerProvider).watchAuthenticatedUserLists(ownerId).listen(
      (lists) {
        state = AsyncValue.data(ListState.loaded(lists));
      },
      onError: (error) {
        state = AsyncValue.data(ListState.error(error.toString()));
      },
    );
  }
}
