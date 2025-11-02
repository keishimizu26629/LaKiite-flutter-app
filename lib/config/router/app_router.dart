import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/auth/auth_state.dart';
import '../../infrastructure/go_router_refresh_notifier.dart';
import '../../presentation/bottom_navigation/bottom_navigation.dart';
import '../../presentation/login/login_page.dart';
import '../../presentation/settings/edit_email_page.dart';
import '../../presentation/settings/edit_name_page.dart';
import '../../presentation/settings/edit_search_id_page.dart';
import '../../presentation/settings/legal_info_page.dart';
import '../../presentation/settings/settings_page.dart';
import '../../presentation/signup/signup.dart';
import '../../presentation/splash/splash_screen.dart';
import '../../presentation/presentation_provider.dart';

/// アプリケーションのルーティング設定を提供するプロバイダー
///
/// 機能:
/// - 認証状態に基づいたリダイレクト処理
/// - アプリケーションの主要なルート定義
///
/// パラメータ:
/// - [ref] Riverpodのプロバイダー参照
///
/// 戻り値:
/// - [GoRouter] 設定されたルーターインスタンス
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(goRouterRefreshProvider);
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    refreshListenable: refreshNotifier,
    initialLocation: SplashScreen.path,
    redirect: (context, state) {
      // スプラッシュ画面の場合はリダイレクトしない
      if (state.location == SplashScreen.path) {
        return null;
      }

      return authState.when(
        data: (authState) {
          final isLoggedIn = authState.status == AuthStatus.authenticated;
          final isLoggingIn = state.location == LoginPage.path;
          final isSigningUp = state.location == SignupPage.path;

          // 未認証ユーザーのリダイレクト処理
          if (!isLoggedIn && !isLoggingIn && !isSigningUp) {
            return LoginPage.path;
          }

          // 認証済みユーザーのリダイレクト処理
          if (isLoggedIn && (isLoggingIn || isSigningUp)) {
            return BottomNavigationPage.path;
          }

          return null;
        },
        loading: () => null,
        error: (_, __) => LoginPage.path,
      );
    },
    routes: [
      GoRoute(
        path: SplashScreen.path,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: BottomNavigationPage.path,
        builder: (context, state) => const BottomNavigationPage(),
      ),
      GoRoute(
        path: LoginPage.path,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: SignupPage.path,
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: SettingsPage.path,
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: EditNamePage.path,
            builder: (context, state) => const EditNamePage(),
          ),
          GoRoute(
            path: EditEmailPage.path,
            builder: (context, state) => const EditEmailPage(),
          ),
          GoRoute(
            path: EditSearchIdPage.path,
            builder: (context, state) => const EditSearchIdPage(),
          ),
          GoRoute(
            path: 'privacy-policy',
            builder: (context, state) => const LegalInfoPage(
              title: 'プライバシーポリシー',
              urlPath: 'privacy-policy',
            ),
          ),
          GoRoute(
            path: 'terms-of-service',
            builder: (context, state) => const LegalInfoPage(
              title: '利用規約',
              urlPath: 'terms-of-service',
            ),
          ),
        ],
      ),
    ],
  );
});
