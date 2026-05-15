import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/auth/auth_state.dart';
import '../presentation_provider.dart';

/// 認証済みの場合のみ [onAuthenticated] を表示する。
/// 認証済み subtree は userId をキーに再生成されるため、
/// ユーザー切り替え時に前ユーザーの widget state を残しにくい。
class AuthDependentBuilder extends ConsumerWidget {
  const AuthDependentBuilder({
    super.key,
    required this.onAuthenticated,
    this.onUnauthenticated,
    this.onLoading,
  });

  final Widget Function(String userId) onAuthenticated;
  final WidgetBuilder? onUnauthenticated;
  final WidgetBuilder? onLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (state) {
        if (state.status == AuthStatus.authenticated && state.user != null) {
          return ProviderScope(
            key: ValueKey(state.user!.id),
            child: KeyedSubtree(
              key: ValueKey('auth-subtree-${state.user!.id}'),
              child: onAuthenticated(state.user!.id),
            ),
          );
        }

        if (onUnauthenticated != null) {
          return onUnauthenticated!(context);
        }

        return const SizedBox.shrink();
      },
      loading: () {
        if (onLoading != null) {
          return onLoading!(context);
        }

        return const Center(child: CircularProgressIndicator());
      },
      error: (_, __) {
        if (onUnauthenticated != null) {
          return onUnauthenticated!(context);
        }

        return const SizedBox.shrink();
      },
    );
  }
}
