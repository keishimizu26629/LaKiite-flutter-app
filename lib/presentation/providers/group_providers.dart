import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/providers/auth_providers.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/service/service_provider.dart';
import '../../domain/entity/group.dart';

/// グループ状態プロバイダー群
///
/// Presentation層のグループ関連プロバイダーを定義します。

/// Application層のNotifierプロバイダーをexport
export 'package:lakiite/application/providers/group_providers.dart'
    show groupNotifierProvider;

/// 認証済みユーザーのグループを監視するStreamプロバイダー
///
/// 認証状態に基づいて適切にグループを提供します。
/// Application層のビジネスロジックに依存しません。
final userGroupsStreamProvider =
    StreamProvider.autoDispose<List<Group>>((ref) async* {
  final authState = await ref.watch(authNotifierProvider.future);

  if (authState.status == AuthStatus.authenticated && authState.user != null) {
    await for (final groups in ref
        .watch(groupManagerProvider)
        .watchUserGroups(authState.user!.id)) {
      yield groups;
    }
  } else {
    yield [];
  }
});
