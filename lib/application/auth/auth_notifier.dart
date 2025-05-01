import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/interfaces/i_auth_repository.dart';
import '../../infrastructure/auth_repository.dart';
import '../../infrastructure/user_fcm_token_service.dart';
import '../../presentation/presentation_provider.dart';
import '../../utils/logger.dart';
import 'auth_state.dart';

part 'auth_notifier.g.dart';

/// 認証リポジトリのグローバルプロバイダー
///
/// パラメータ:
/// - [ref] Riverpodのプロバイダー参照
///
/// 依存:
/// - [userRepositoryProvider] ユーザー情報管理用（presentation_provider.dartで定義）
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
  late final UserFcmTokenService _fcmTokenService;

  @override
  FutureOr<AuthState> build() async {
    // FCMトークンサービスを初期化
    _fcmTokenService = UserFcmTokenService();

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
        // FCMトークンを更新
        await _fcmTokenService.updateCurrentUserFcmToken();
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
        // FCMトークンを更新
        await _fcmTokenService.updateCurrentUserFcmToken();
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
      try {
        // FCMトークンを削除
        await _fcmTokenService.removeFcmToken();

        // Firestoreのキャッシュをクリア
        try {
          await FirebaseFirestore.instance.terminate();
          await FirebaseFirestore.instance.clearPersistence();
        } catch (e) {
          AppLogger.error('Firestoreキャッシュクリアエラー: $e');
        }

        // 関連するRiverpodプロバイダーをリセット
        ref.invalidateSelf();

        // ユーザー関連のプロバイダーを無効化
        ref.invalidate(userRepositoryProvider);

        // スケジュール関連のプロバイダーも無効化
        ref.invalidate(scheduleNotifierProvider);
        ref.invalidate(scheduleRepositoryProvider);

        // グループとリスト関連のプロバイダーも無効化
        ref.invalidate(groupNotifierProvider);
        ref.invalidate(groupRepositoryProvider);
        ref.invalidate(listNotifierProvider);
        ref.invalidate(listRepositoryProvider);

        // ストリームプロバイダーも無効化
        ref.invalidate(userListsStreamProvider);
        ref.invalidate(userGroupsStreamProvider);
        ref.invalidate(userFriendsStreamProvider);
        ref.invalidate(userFriendsProvider);

        // 最後に認証をサインアウト
        await _authRepository.signOut();

        return AuthState.unauthenticated();
      } catch (e) {
        AppLogger.error('サインアウトエラー: $e');
        rethrow;
      }
    });
  }
}
