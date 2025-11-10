import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/di/repository_providers.dart';

/// 認証状態プロバイダー群
///
/// 認証関連のプロバイダーを定義します。

/// 認証状態の変更を監視するプロバイダー
final authStateProvider = StreamProvider.autoDispose((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

/// 認証状態を管理するNotifierプロバイダー
final authNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
