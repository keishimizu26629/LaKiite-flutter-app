import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/list/list_notifier.dart';
import 'package:lakiite/application/list/list_state.dart';
import 'package:lakiite/domain/service/service_provider.dart';
import '../../domain/entity/list.dart';

/// リスト状態プロバイダー群
///
/// リスト関連のプロバイダーを定義します。

/// リスト状態を管理するNotifierプロバイダー
final listNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ListNotifier, ListState>(
  ListNotifier.new,
);

/// 認証済みユーザーのリストを監視するStreamプロバイダー
///
/// 認証状態に基づいて適切にリストを提供します。
/// Application層のビジネスロジックに依存しません。
final userListsStreamProvider =
    StreamProvider.autoDispose<List<UserList>>((ref) async* {
  final authState = await ref.watch(authNotifierProvider.future);

  if (authState.status == AuthStatus.authenticated && authState.user != null) {
    await for (final lists in ref
        .watch(listManagerProvider)
        .watchAuthenticatedUserLists(authState.user!.id)) {
      yield lists;
    }
  } else {
    yield [];
  }
});

/// 特定のリストをリアルタイムで監視するStreamプロバイダー
///
/// [listId] 監視対象のリストID
final listStreamProvider =
    StreamProvider.family<UserList?, String>((ref, listId) {
  return ref.watch(listManagerProvider).watchList(listId);
});
