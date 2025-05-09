import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
/// - アカウント削除処理
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
        try {
          await _fcmTokenService.removeFcmToken();
        } catch (e) {
          AppLogger.error('FCMトークン削除エラー（無視して続行）: $e');
          // トークン削除に失敗しても処理を続行
        }

        // Firestoreのキャッシュをクリア
        try {
          await FirebaseFirestore.instance.terminate();
          await FirebaseFirestore.instance.clearPersistence();
        } catch (e) {
          AppLogger.error('Firestoreキャッシュクリアエラー（無視して続行）: $e');
          // キャッシュクリアに失敗しても処理を続行
        }

        // 関連するRiverpodプロバイダーをリセット
        try {
          // 自身のプロバイダーを無効化
          ref.invalidateSelf();

          // ユーザー関連のプロバイダーを無効化
          try {
            ref.invalidate(userRepositoryProvider);
          } catch (e) {
            AppLogger.warning('userRepositoryProvider無効化エラー: $e');
          }

          // その他のプロバイダーを個別に無効化し、エラーを捕捉
          try {
            ref.invalidate(scheduleNotifierProvider);
          } catch (e) {
            // エラーは無視
          }

          try {
            ref.invalidate(scheduleRepositoryProvider);
          } catch (e) {
            // エラーは無視
          }

          try {
            ref.invalidate(groupNotifierProvider);
          } catch (e) {
            // エラーは無視
          }

          try {
            ref.invalidate(groupRepositoryProvider);
          } catch (e) {
            // エラーは無視
          }

          try {
            ref.invalidate(listNotifierProvider);
          } catch (e) {
            // エラーは無視
          }

          try {
            ref.invalidate(listRepositoryProvider);
          } catch (e) {
            // エラーは無視
          }

          try {
            ref.invalidate(userListsStreamProvider);
          } catch (e) {
            // エラーは無視
          }

          try {
            ref.invalidate(userGroupsStreamProvider);
          } catch (e) {
            // エラーは無視
          }

          try {
            ref.invalidate(userFriendsStreamProvider);
          } catch (e) {
            // エラーは無視
          }

          try {
            ref.invalidate(userFriendsProvider);
          } catch (e) {
            // エラーは無視
          }
        } catch (e) {
          AppLogger.error('プロバイダー無効化エラー（無視して続行）: $e');
          // プロバイダー無効化に失敗しても処理を続行
        }

        // 最後に認証をサインアウト
        await _authRepository.signOut();

        return AuthState.unauthenticated();
      } catch (e) {
        AppLogger.error('サインアウトエラー: $e');
        rethrow;
      }
    });
  }

  /// アカウントを削除する
  ///
  /// 処理:
  /// - ユーザーデータを削除
  /// - 認証情報を削除
  /// - 関連するプロバイダーをリセット
  ///
  /// 戻り値:
  /// - 処理が成功した場合は true
  /// - 失敗した場合は例外をスロー
  Future<bool> deleteAccount() async {
    // ローディング状態に設定
    state = const AsyncLoading();

    // アカウント削除処理を実行
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

      // アカウントを削除
      final success = await _authRepository.deleteAccount();

      // 認証状態を更新
      if (success) {
        state = AsyncData(AuthState.unauthenticated());
      }

      return success;
    } catch (e) {
      AppLogger.error('アカウント削除エラー: $e');
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}
