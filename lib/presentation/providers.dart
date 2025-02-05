import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum AuthStatus {
  authenticated,
  unauthenticated,
  loading
}

class AuthState {
  final AuthStatus status;
  final User? user;

  const AuthState({
    required this.status,
    this.user,
  });

  factory AuthState.authenticated(User user) => AuthState(
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

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Ref _ref;

  AuthNotifier(this._ref) : super(AuthState.unauthenticated()) {
    _ref.listen(authStateProvider, (previous, next) {
      if (next.value != null) {
        state = AuthState.authenticated(next.value!);
      } else {
        state = AuthState.unauthenticated();
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = AuthState.loading();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      state = AuthState.unauthenticated();
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = AuthState.loading();
    try {
      await _auth.signOut();
      state = AuthState.unauthenticated();
    } catch (e) {
      rethrow;
    }
  }
}
