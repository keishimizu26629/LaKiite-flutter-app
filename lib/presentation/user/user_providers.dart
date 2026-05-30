import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/entity/user.dart';

/// Integrated user read model for presentation code that needs a user by id.
///
/// This provider stays in the user presentation feature so generic user reads
/// are not mixed into broad app-level presentation exports.
final userStreamProvider =
    StreamProvider.autoDispose.family<UserModel?, String>((ref, userId) {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (state) {
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value(null);
      }

      return ref.watch(userManagerProvider).watchIntegratedUser(userId);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});
