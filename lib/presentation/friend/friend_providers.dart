import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/entity/user.dart';

/// Authenticated user's friends exposed as presentation state for friend UIs.
///
/// Keep this provider in the friend feature so friend screens do not depend on
/// a broad presentation provider file for their primary read model.
final userFriendsStreamProvider =
    StreamProvider.autoDispose<List<PublicUserModel>>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (state) {
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value([]);
      }

      return ref
          .watch(userManagerProvider)
          .watchAuthenticatedUserFriends(state.user!.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// One-shot friend list read model for refresh-style friend workflows.
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
