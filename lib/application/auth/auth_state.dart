import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entity/user.dart';

part 'auth_state.freezed.dart';

@freezed
class AuthState with _$AuthState {
  const AuthState._();

  const factory AuthState({
    required AuthStatus status,
    UserModel? user,
  }) = _AuthState;

  factory AuthState.authenticated(UserModel user) => AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );

  factory AuthState.unauthenticated() => const AuthState(
        status: AuthStatus.unauthenticated,
      );

  factory AuthState.loading() => const AuthState(
        status: AuthStatus.loading,
      );
}

enum AuthStatus {
  authenticated,
  unauthenticated,
  loading
}
