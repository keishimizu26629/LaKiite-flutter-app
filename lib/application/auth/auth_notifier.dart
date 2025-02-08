import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/interfaces/i_auth_repository.dart';
import '../../domain/interfaces/i_user_repository.dart';
import '../../infrastructure/auth_repository.dart';
import '../../infrastructure/user_repository.dart';
import 'auth_state.dart';

part 'auth_notifier.g.dart';

// グローバルプロバイダー
final userRepositoryProvider = Provider<IUserRepository>((ref) {
  return UserRepository();
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    ref.watch(userRepositoryProvider),
  );
});

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<AuthState> build() async {
    return AuthState.unauthenticated();
  }

  IAuthRepository get _authRepository => ref.watch(authRepositoryProvider);

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await _authRepository.signIn(email, password);
      if (user != null) {
        return AuthState.authenticated(user);
      } else {
        return AuthState.unauthenticated();
      }
    });
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await _authRepository.signUp(email, password, name);
      if (user != null) {
        return AuthState.authenticated(user);
      } else {
        return AuthState.unauthenticated();
      }
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signOut();
      return AuthState.unauthenticated();
    });
  }
}
