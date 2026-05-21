import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../domain/interfaces/i_auth_repository.dart';
import '../../domain/entity/user.dart';
import '../../infrastructure/auth_repository.dart';
import '../../infrastructure/user_fcm_token_service.dart';
import '../../app/di/providers.dart';
import '../../utils/logger.dart';
import '../../utils/webview_monitor.dart';
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
  UserFcmTokenService? _fcmTokenService;

  @override
  FutureOr<AuthState> build() async {
    // FCMトークンサービスを初期化（テスト環境での例外処理を含む）
    try {
      _fcmTokenService = UserFcmTokenService();
    } catch (e) {
      // テスト環境やFirebase未初期化の場合は警告ログを出して続行
      AppLogger.warning('FCMトークンサービス初期化エラー（テスト環境の可能性）: $e');
    }

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
    AppLogger.debugOnly('signIn開始: email=$email');

    // ローディング状態に設定
    state = const AsyncLoading();

    // サインイン処理を実行
    final signInResult = await AsyncValue.guard(() async {
      final user = await _authRepository.signIn(email, password);
      // サインイン結果に応じて状態を更新
      if (user != null) {
        AppLogger.debug('サインイン成功: ユーザーID=${user.id}');

        // FCMトークンを更新（リトライ付き）
        try {
          AppLogger.debug('サインイン: FCMトークン更新を開始');
          await _fcmTokenService?.updateCurrentUserFcmToken();
          AppLogger.debug('サインイン: FCMトークン更新完了');
        } catch (e) {
          AppLogger.error('サインイン: FCMトークン更新エラー - $e');
          // FCMトークンの更新に失敗してもサインインは継続
        }
        return AuthState.authenticated(user);
      } else {
        AppLogger.warning('サインイン失敗: ユーザーがnull');
        return AuthState.unauthenticated();
      }
    });
    state = signInResult;

    state.whenOrNull(
      data: (authState) => AppLogger.debugOnly(
          'signIn完了: status=${authState.status}, userId=${authState.user?.id}'),
      error: (error, stackTrace) =>
          AppLogger.errorOnly('signIn失敗', error, stackTrace),
    );

    if (signInResult.hasError) {
      Error.throwWithStackTrace(
        signInResult.error!,
        signInResult.stackTrace ?? StackTrace.current,
      );
    }
  }

  /// 新規ユーザー登録を行う
  ///
  /// パラメータ:
  /// - [email] 登録するメールアドレス
  /// - [password] 設定するパスワード
  /// - [name] ユーザー名
  /// - [displayName] 表示名（省略時はnameを使用）
  ///
  /// 戻り値:
  /// - 登録成功時は[AuthState.authenticated]
  /// - 失敗時は[AuthState.unauthenticated]
  Future<void> signUp(String email, String password, String name,
      {String? displayName}) async {
    AppLogger.debugOnly(
        'signUp開始: email=$email, name=$name, displayName=${displayName ?? '(null)'}');

    // ローディング状態に設定
    state = const AsyncLoading();

    // ユーザー登録処理を実行
    final signUpResult = await AsyncValue.guard(() async {
      // AuthRepositoryは従来通りnameのみを受け取るため、
      // displayNameの処理は後でupdateProfileで対応する
      final user = await _authRepository.signUp(email, password, name);

      if (user != null) {
        // displayNameが指定されている場合はプロフィールを更新
        UserModel finalUser = user;
        if (displayName != null &&
            displayName.isNotEmpty &&
            displayName != name) {
          finalUser = user.updateProfile(displayName: displayName);
        }

        await ref.read(userRepositoryProvider).updateUser(finalUser);
        AppLogger.debugOnly('signUp後プロフィール更新完了: userId=${finalUser.id}');

        AppLogger.debug('サインアップ成功: ユーザーID=${finalUser.id}');

        // FCMトークンを更新（リトライ付き）
        try {
          AppLogger.debug('サインアップ: FCMトークン更新を開始');
          await _fcmTokenService?.updateCurrentUserFcmToken();
          AppLogger.debug('サインアップ: FCMトークン更新完了');
        } catch (e) {
          AppLogger.error('サインアップ: FCMトークン更新エラー - $e');
          // FCMトークンの更新に失敗してもサインアップは継続
        }
        return AuthState.authenticated(finalUser);
      } else {
        AppLogger.warning('サインアップ失敗: ユーザーがnull');
        return AuthState.unauthenticated();
      }
    });
    state = signUpResult;

    state.whenOrNull(
      data: (authState) => AppLogger.debugOnly(
          'signUp完了: status=${authState.status}, userId=${authState.user?.id}'),
      error: (error, stackTrace) =>
          AppLogger.errorOnly('signUp失敗', error, stackTrace),
    );

    if (signUpResult.hasError) {
      Error.throwWithStackTrace(
        signUpResult.error!,
        signUpResult.stackTrace ?? StackTrace.current,
      );
    }
  }

  /// サインアウトを行う
  ///
  /// 処理:
  /// - 現在のユーザーをサインアウト
  /// - 認証状態を未認証に更新
  /// - 全てのキャッシュをクリア
  Future<void> signOut() async {
    // ローディング状態に設定
    state = const AsyncLoading();

    // サインアウト処理を実行
    state = await AsyncValue.guard(() async {
      try {
        AppLogger.debug('サインアウト処理を開始します');

        // 1. 先に認証をサインアウトして、Router と認証状態を安定させる
        await _authRepository.signOut();
        AppLogger.debug('認証サインアウトが完了しました');

        // 2. FCMトークンを削除
        try {
          if (_fcmTokenService != null) {
            await _fcmTokenService!.removeFcmToken();
            AppLogger.debug('FCMトークンを削除しました');
          } else {
            AppLogger.debug('FCMトークンサービスが初期化されていないため、FCMトークン削除をスキップします');
          }
        } catch (e) {
          AppLogger.warning('FCMトークン削除エラー（無視して続行）: $e');
        }

        // 3. WebView 関連の強制クリーンアップ
        try {
          // WebView インスタンスの状態を確認
          WebViewMonitor.printStatus();
          if (WebViewMonitor.hasUnreleasedInstances()) {
            AppLogger.warning('未解放のWebViewインスタンスが検出されました');
          }

          // iOS WebView のキャッシュを強制クリア
          if (Platform.isIOS) {
            await _clearWebViewCaches();
            await _resetPlatformViews();
          }

          // WebView インスタンスモニターをクリア
          WebViewMonitor.clearAll();
          AppLogger.debug('WebView インスタンスモニターをクリアしました');
        } catch (e) {
          AppLogger.warning('WebView キャッシュクリアエラー（無視して続行）: $e');
        }

        AppLogger.debug('サインアウト処理が正常に完了しました');
        return AuthState.unauthenticated();
      } catch (e) {
        AppLogger.error('サインアウトエラー: $e');
        rethrow;
      }
    });
  }

  /// WebViewキャッシュをクリアする（iOS用）
  Future<void> _clearWebViewCaches() async {
    try {
      // iOS の場合のみ実行
      if (Platform.isIOS) {
        // WKWebView のキャッシュを完全にクリア
        await const MethodChannel('flutter/webview')
            .invokeMethod('clearWebViewCache');
        AppLogger.debug('WebViewキャッシュをクリアしました');
      }
    } on MissingPluginException catch (e) {
      AppLogger.warning('WebViewキャッシュクリアをスキップ: $e');
    } catch (e) {
      AppLogger.warning('WebView キャッシュクリア失敗: $e');
    }
  }

  /// プラットフォームビューをリセットする（iOS用）
  Future<void> _resetPlatformViews() async {
    try {
      if (Platform.isIOS) {
        // iOS WebView プラットフォームビューのリセット
        const MethodChannel('flutter/platform_views')
            .setMethodCallHandler(null);
        AppLogger.debug('プラットフォームビューをリセットしました');
      }
    } catch (e) {
      AppLogger.warning('プラットフォームビューリセット失敗: $e');
    }
  }

  /// アカウントを削除する
  ///
  /// 処理:
  /// - ユーザーデータを削除
  /// - 認証情報を削除
  /// - 関連するプロバイダーをリセット
  /// - 全てのキャッシュをクリア
  ///
  /// 戻り値:
  /// - 処理が成功した場合は true
  /// - 失敗した場合は例外をスロー
  Future<bool> deleteAccount() async {
    // ローディング状態に設定
    state = const AsyncLoading();

    // アカウント削除処理を実行
    try {
      AppLogger.debug('アカウント削除処理を開始します');
      final success = await _authRepository.deleteAccount();

      try {
        if (_fcmTokenService != null) {
          await _fcmTokenService!.removeFcmToken();
          AppLogger.debug('FCMトークンを削除しました');
        } else {
          AppLogger.debug('FCMトークンサービスが初期化されていないため、FCMトークン削除をスキップします');
        }
      } catch (e) {
        AppLogger.warning('FCMトークン削除エラー（無視して続行）: $e');
      }

      if (success) {
        state = AsyncData(AuthState.unauthenticated());
        AppLogger.debug('アカウント削除処理が正常に完了しました');
      }

      return success;
    } catch (e) {
      AppLogger.error('アカウント削除エラー: $e');
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }

  /// パスワードで再認証を行う
  ///
  /// パラメータ:
  /// - [password] 現在のパスワード
  ///
  /// 戻り値:
  /// - 再認証が成功したかどうかを示すbool値
  Future<bool> reauthenticateWithPassword(String password) async {
    try {
      AppLogger.debug('再認証処理を開始します');
      final success =
          await _authRepository.reauthenticateWithPassword(password);
      if (success) {
        AppLogger.debug('再認証が正常に完了しました');
      }
      return success;
    } catch (e) {
      AppLogger.error('再認証エラー: $e');
      rethrow;
    }
  }

  /// 再認証を行ってからアカウントを削除する
  ///
  /// パラメータ:
  /// - [password] 現在のパスワード
  ///
  /// 戻り値:
  /// - 処理が成功した場合は true
  /// - 失敗した場合は例外をスロー
  Future<bool> deleteAccountWithReauth(String password) async {
    // ローディング状態に設定
    state = const AsyncLoading();

    // アカウント削除処理を実行
    try {
      AppLogger.debug('再認証付きアカウント削除処理を開始します');
      final success = await _authRepository.deleteAccountWithReauth(password);

      try {
        if (_fcmTokenService != null) {
          await _fcmTokenService!.removeFcmToken();
          AppLogger.debug('FCMトークンを削除しました');
        } else {
          AppLogger.debug('FCMトークンサービスが初期化されていないため、FCMトークン削除をスキップします');
        }
      } catch (e) {
        AppLogger.warning('FCMトークン削除エラー（無視して続行）: $e');
      }

      if (success) {
        state = AsyncData(AuthState.unauthenticated());
        AppLogger.debug('再認証付きアカウント削除処理が正常に完了しました');
      }

      return success;
    } catch (e) {
      AppLogger.error('再認証付きアカウント削除エラー: $e');
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}
