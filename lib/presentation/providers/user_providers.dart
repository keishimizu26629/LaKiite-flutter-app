import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/service/service_provider.dart';
import '../../domain/entity/user.dart';

/// ユーザー状態プロバイダー群
///
/// ユーザー関連のプロバイダーを定義します。

/// 統合されたユーザー情報をリアルタイムで監視するStreamプロバイダー
///
/// [userId] 監視対象のユーザーID
///
/// UserManagerを使用して統合されたユーザー情報を提供します。
final userStreamProvider =
    StreamProvider.family<UserModel?, String>((ref, userId) {
  return ref.watch(userManagerProvider).watchIntegratedUser(userId);
});

/// 認証済みユーザーのフレンド一覧を監視するStreamプロバイダー
///
/// UserManagerを使用してフレンド情報を提供します。
final userFriendsStreamProvider =
    StreamProvider.autoDispose<List<PublicUserModel>>((ref) async* {
  final authState = await ref.watch(authNotifierProvider.future);

  if (authState.status == AuthStatus.authenticated && authState.user != null) {
    await for (final friends in ref
        .watch(userManagerProvider)
        .watchAuthenticatedUserFriends(authState.user!.id)) {
      yield friends;
    }
  } else {
    yield [];
  }
});

/// 認証済みユーザーのフレンド一覧を取得するFutureプロバイダー
/// アプリ起動時、承認時、手動更新時にのみデータを再取得する
final userFriendsProvider =
    FutureProvider.autoDispose<List<PublicUserModel>>((ref) async {
  final authState = await ref.watch(authNotifierProvider.future);

  if (authState.status == AuthStatus.authenticated && authState.user != null) {
    return await ref
        .watch(userManagerProvider)
        .getAuthenticatedUserFriends(authState.user!.id);
  } else {
    return [];
  }
});
