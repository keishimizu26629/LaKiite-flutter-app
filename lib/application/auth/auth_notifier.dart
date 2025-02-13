import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/interfaces/i_auth_repository.dart';
import '../../domain/interfaces/i_user_repository.dart';
import '../../infrastructure/auth_repository.dart';
import '../../infrastructure/user_repository.dart';
import 'auth_state.dart';

part 'auth_notifier.g.dart';

/// ユーザーリポジトリのグローバルプロバイダー
///
/// パラメータ:
/// - [ref] Riverpodのプロバイダー参照
///
/// 戻り値:
/// - [IUserRepository] ユーザー操作用のリポジトリインスタンス
final userRepositoryProvider = Provider<IUserRepository>((ref) {
  return UserRepository();
});

/// 認証リポジトリのグローバルプロバイダー
///
/// パラメータ:
/// - [ref] Riverpodのプロバイダー参照
///
/// 依存:
/// - [userRepositoryProvider] ユーザー情報管理用
/// - [FirebaseAuth] 認証基盤
///
/// 戻り値:
/// - [IAuthRepository] 認証操作用のリポジトリインスタンス
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    ref.watch(userRepositoryProvider),
  );
});

/// 認証状態のストリームを提供するプロバイダー
final authStateStreamProvider = StreamProvider.autoDispose<AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges().map((user) {
    if (user != null) {
      return AuthState.authenticated(user);
    }
    return AuthState.unauthenticated();
  });
});

/// 認証状態を管理するNotifierクラス
///
/// 機能:
/// - 認証状態の監視と管理
/// - サインイン処理
/// - サインアップ処理
/// - サインアウト処理
///
/// 依存:
/// - [authRepositoryProvider] 認証操作用
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<AuthState> build() async {
    // authStateStreamProviderの最新の値を監視
    final authState = await ref.watch(authStateStreamProvider.future);
    return authState;
  }

  /// 認証リポジトリへの参照を取得
  IAuthRepository get _authRepository => ref.watch(authRepositoryProvider);

  /// メールアドレスとパスワードでサインインを行う
  ///
  /// パラメータ:
  /// - [email] サインインに使用するメールアドレス
  /// - [password] サインインに使用するパスワード
  ///
  /// 戻り値:
  /// - 認証成功時は[AuthState.authenticated]
  /// - 失敗時は[AuthState.unauthenticated]
  Future<void> signIn(String email, String password) async {
    // ローディング状態に設定
    state = const AsyncLoading();

    // サインイン処理を実行
    state = await AsyncValue.guard(() async {
      final user = await _authRepository.signIn(email, password);
      // サインイン結果に応じて状態を更新
      if (user != null) {
        return AuthState.authenticated(user);
      } else {
        return AuthState.unauthenticated();
      }
    });
  }

  /// 新規ユーザー登録を行う
  ///
  /// パラメータ:
  /// - [email] 登録するメールアドレス
  /// - [password] 設定するパスワード
  /// - [name] ユーザー名
  ///
  /// 戻り値:
  /// - 登録成功時は[AuthState.authenticated]
  /// - 失敗時は[AuthState.unauthenticated]
  Future<void> signUp(String email, String password, String name) async {
    // ローディング状態に設定
    state = const AsyncLoading();

    // ユーザー登録処理を実行
    state = await AsyncValue.guard(() async {
      final user = await _authRepository.signUp(email, password, name);
      // 登録結果に応じて状態を更新
      if (user != null) {
        return AuthState.authenticated(user);
      } else {
        return AuthState.unauthenticated();
      }
    });
  }

  /// サインアウトを行う
  ///
  /// 処理:
  /// - 現在のユーザーをサインアウト
  /// - 認証状態を未認証に更新
  Future<void> signOut() async {
    // ローディング状態に設定
    state = const AsyncLoading();

    // サインアウト処理を実行
    state = await AsyncValue.guard(() async {
      await _authRepository.signOut();
      return AuthState.unauthenticated();
    });
  }
}
