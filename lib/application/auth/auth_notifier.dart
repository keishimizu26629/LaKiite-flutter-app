import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../domain/interfaces/i_auth_repository.dart';
import '../../domain/entity/user.dart';
import '../../infrastructure/user_fcm_token_service.dart';
import '../../di/repository_providers.dart';
import '../../infrastructure/user_repository.dart';
import '../../infrastructure/schedule_repository.dart';
import '../providers/application_providers.dart';
import '../../utils/logger.dart';
import '../../utils/webview_monitor.dart';
import 'auth_state.dart';

part 'auth_notifier.g.dart';

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
    // ローディング状態に設定
    state = const AsyncLoading();

    // サインイン処理を実行
    state = await AsyncValue.guard(() async {
      final user = await _authRepository.signIn(email, password);
      // サインイン結果に応じて状態を更新
      if (user != null) {
        AppLogger.debug('サインイン成功: ユーザーID=${user.id}');

        // FCMトークンを更新（リトライ付き）
        try {
          AppLogger.debug('サインイン: FCMトークン更新を開始');
          await _fcmTokenService!.updateCurrentUserFcmToken();
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
    // ローディング状態に設定
    state = const AsyncLoading();

    // ユーザー登録処理を実行
    state = await AsyncValue.guard(() async {
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
          await ref.read(userRepositoryProvider).updateUser(finalUser);
        }

        AppLogger.debug('サインアップ成功: ユーザーID=${finalUser.id}');

        // FCMトークンを更新（リトライ付き）
        try {
          AppLogger.debug('サインアップ: FCMトークン更新を開始');
          await _fcmTokenService!.updateCurrentUserFcmToken();
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

        // 1. 既存のリポジトリインスタンスのキャッシュを明示的にクリア
        try {
          final userRepo = ref.read(userRepositoryProvider);
          if (userRepo is UserRepository) {
            userRepo.clearCache();
            AppLogger.debug('UserRepositoryキャッシュをクリアしました');
          }
        } catch (e) {
          AppLogger.warning('UserRepositoryキャッシュクリアエラー（無視して続行）: $e');
        }

        try {
          final scheduleRepo = ref.read(scheduleRepositoryProvider);
          if (scheduleRepo is ScheduleRepository) {
            scheduleRepo.clearCache();
            AppLogger.debug('ScheduleRepositoryキャッシュをクリアしました');
          }
        } catch (e) {
          AppLogger.warning('ScheduleRepositoryキャッシュクリアエラー（無視して続行）: $e');
        }

        // 2. カレンダー関連のStateProviderキャッシュはPresentation層で処理
        // Application層からは直接参照しない（アーキテクチャ違反を回避）

        // 3. MyPageのキャッシュはPresentation層で処理
        // Application層からは直接参照しない（アーキテクチャ違反を回避）

        // 4. FCMトークンを削除
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

        // 5. WebView 関連の強制クリーンアップ
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

        // 6. Firestoreのキャッシュをクリア
        try {
          await FirebaseFirestore.instance.terminate();
          await FirebaseFirestore.instance.clearPersistence();
          AppLogger.debug('Firestoreキャッシュをクリアしました');
        } catch (e) {
          AppLogger.error('Firestoreキャッシュクリアエラー（無視して続行）: $e');
          // キャッシュクリアに失敗しても処理を続行
        }

        // 6. 関連するRiverpodプロバイダーをリセット
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

          // Presentation層のストリームプロバイダーはPresentation層で処理
          // Application層からは直接参照しない（アーキテクチャ違反を回避）

          AppLogger.debug('プロバイダーを無効化しました');
        } catch (e) {
          AppLogger.error('プロバイダー無効化エラー（無視して続行）: $e');
          // プロバイダー無効化に失敗しても処理を続行
        }

        // 7. 最後に認証をサインアウト
        await _authRepository.signOut();
        AppLogger.debug('認証サインアウトが完了しました');

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
        const MethodChannel('flutter/webview')
            .invokeMethod('clearWebViewCache');
        AppLogger.debug('WebViewキャッシュをクリアしました');
      }
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

      // 1. 既存のリポジトリインスタンスのキャッシュを明示的にクリア
      try {
        final userRepo = ref.read(userRepositoryProvider);
        if (userRepo is UserRepository) {
          userRepo.clearCache();
          AppLogger.debug('UserRepositoryキャッシュをクリアしました');
        }
      } catch (e) {
        AppLogger.warning('UserRepositoryキャッシュクリアエラー（無視して続行）: $e');
      }

      try {
        final scheduleRepo = ref.read(scheduleRepositoryProvider);
        if (scheduleRepo is ScheduleRepository) {
          scheduleRepo.clearCache();
          AppLogger.debug('ScheduleRepositoryキャッシュをクリアしました');
        }
      } catch (e) {
        AppLogger.warning('ScheduleRepositoryキャッシュクリアエラー（無視して続行）: $e');
      }

      // 2. カレンダー関連のStateProviderキャッシュはPresentation層で処理
      // Application層からは直接参照しない（アーキテクチャ違反を回避）

      // 3. MyPageのキャッシュはPresentation層で処理
      // Application層からは直接参照しない（アーキテクチャ違反を回避）

      // 4. FCMトークンを削除
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

      // 5. Firestoreのキャッシュをクリア
      try {
        await FirebaseFirestore.instance.terminate();
        await FirebaseFirestore.instance.clearPersistence();
        AppLogger.debug('Firestoreキャッシュをクリアしました');
      } catch (e) {
        AppLogger.error('Firestoreキャッシュクリアエラー: $e');
      }

      // 6. アカウントを削除
      final success = await _authRepository.deleteAccount();

      // 7. 認証状態を更新
      if (success) {
        state = AsyncData(AuthState.unauthenticated());
        AppLogger.debug('アカウント削除処理が正常に完了しました');

        // 削除成功後に関連するRiverpodプロバイダーをリセット
        try {
          // ユーザー関連のプロバイダーを無効化
          ref.invalidate(userRepositoryProvider);

          // Application層のプロバイダーを無効化
          ref.invalidate(scheduleNotifierProvider);
          ref.invalidate(groupNotifierProvider);
          ref.invalidate(listNotifierProvider);

          // Repository層のプロバイダーを無効化
          ref.invalidate(scheduleRepositoryProvider);
          ref.invalidate(groupRepositoryProvider);
          ref.invalidate(listRepositoryProvider);

          // Presentation層のストリームプロバイダーはPresentation層で処理
          // Application層からは直接参照しない（アーキテクチャ違反を回避）

          AppLogger.debug('プロバイダーを無効化しました');
        } catch (e) {
          AppLogger.warning('プロバイダー無効化エラー（無視して続行）: $e');
        }
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

      // 1. 既存のリポジトリインスタンスのキャッシュを明示的にクリア
      try {
        final userRepo = ref.read(userRepositoryProvider);
        if (userRepo is UserRepository) {
          userRepo.clearCache();
          AppLogger.debug('UserRepositoryキャッシュをクリアしました');
        }
      } catch (e) {
        AppLogger.warning('UserRepositoryキャッシュクリアエラー（無視して続行）: $e');
      }

      try {
        final scheduleRepo = ref.read(scheduleRepositoryProvider);
        if (scheduleRepo is ScheduleRepository) {
          scheduleRepo.clearCache();
          AppLogger.debug('ScheduleRepositoryキャッシュをクリアしました');
        }
      } catch (e) {
        AppLogger.warning('ScheduleRepositoryキャッシュクリアエラー（無視して続行）: $e');
      }

      // 2. カレンダー関連のStateProviderキャッシュはPresentation層で処理
      // Application層からは直接参照しない（アーキテクチャ違反を回避）

      // 3. MyPageのキャッシュはPresentation層で処理
      // Application層からは直接参照しない（アーキテクチャ違反を回避）

      // 4. FCMトークンを削除
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

      // 5. Firestoreのキャッシュをクリア
      try {
        await FirebaseFirestore.instance.terminate();
        await FirebaseFirestore.instance.clearPersistence();
        AppLogger.debug('Firestoreキャッシュをクリアしました');
      } catch (e) {
        AppLogger.error('Firestoreキャッシュクリアエラー: $e');
      }

      // 6. 再認証付きでアカウントを削除（AuthRepositoryの新しいメソッドを使用）
      final authRepo = _authRepository as dynamic;
      if (authRepo.deleteAccountWithReauth != null) {
        final success = await authRepo.deleteAccountWithReauth(password);

        // 7. 認証状態を更新
        if (success) {
          state = AsyncData(AuthState.unauthenticated());
          AppLogger.debug('再認証付きアカウント削除処理が正常に完了しました');

          // 削除成功後に関連するRiverpodプロバイダーをリセット
          try {
            // ユーザー関連のプロバイダーを無効化
            ref.invalidate(userRepositoryProvider);

            // Application層のプロバイダーを無効化
            ref.invalidate(scheduleNotifierProvider);
            ref.invalidate(groupNotifierProvider);
            ref.invalidate(listNotifierProvider);

            // Repository層のプロバイダーを無効化
            ref.invalidate(scheduleRepositoryProvider);
            ref.invalidate(groupRepositoryProvider);
            ref.invalidate(listRepositoryProvider);

            // Presentation層のストリームプロバイダーはPresentation層で処理
            // Application層からは直接参照しない（アーキテクチャ違反を回避）

            AppLogger.debug('プロバイダーを無効化しました');
          } catch (e) {
            AppLogger.warning('プロバイダー無効化エラー（無視して続行）: $e');
          }
        }

        return success;
      } else {
        // フォールバック：先に再認証してから削除
        await reauthenticateWithPassword(password);
        return await deleteAccount();
      }
    } catch (e) {
      AppLogger.error('再認証付きアカウント削除エラー: $e');
      state = AsyncError(e, StackTrace.current);
      rethrow;
    }
  }
}
