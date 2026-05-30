import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/entity/list.dart';

/// Single list read model for list detail UIs.
final listStreamProvider =
    StreamProvider.autoDispose.family<UserList?, String>((ref, listId) {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (state) {
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value(null);
      }

      return ref.watch(listManagerProvider).watchList(listId);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// Authenticated user's lists exposed as presentation state for list UIs.
///
/// This belongs to the list feature because it represents the list screen's
/// primary read model, while repositories and managers remain in lower layers.
final userListsStreamProvider =
    StreamProvider.autoDispose<List<UserList>>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (state) {
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value([]);
      }

      return ref
          .watch(listManagerProvider)
          .watchAuthenticatedUserLists(state.user!.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});
