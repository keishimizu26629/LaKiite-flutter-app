import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/providers/auth_providers.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/service/service_provider.dart';
import '../../domain/entity/list.dart';

/// リスト状態プロバイダー群
///
/// Presentation層のリスト関連プロバイダーを定義します。

/// Application層のNotifierプロバイダーをexport
export 'package:lakiite/application/providers/list_providers.dart'
    show listNotifierProvider;

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
