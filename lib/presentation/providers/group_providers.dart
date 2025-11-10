import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/group/group_notifier.dart';
import 'package:lakiite/application/group/group_state.dart';
import 'package:lakiite/domain/service/service_provider.dart';
import '../../domain/entity/group.dart';

/// グループ状態プロバイダー群
///
/// グループ関連のプロバイダーを定義します。

/// グループ状態を管理するNotifierプロバイダー
final groupNotifierProvider =
    AutoDisposeAsyncNotifierProvider<GroupNotifier, GroupState>(
  GroupNotifier.new,
);

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
