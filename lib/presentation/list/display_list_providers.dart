import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/entity/display_list.dart';

final userDisplayListsStreamProvider =
    StreamProvider.autoDispose<List<DisplayList>>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (state) {
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value([]);
      }

      return ref
          .watch(displayListRepositoryProvider)
          .watchDisplayLists(state.user!.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});
