import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'config/app_config.dart';
import 'infrastructure/go_router_refresh_notifier.dart';
import 'infrastructure/admob_service.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/login/login_page.dart';
import 'presentation/signup/signup.dart';
import 'presentation/bottom_navigation/bottom_navigation.dart';
import 'presentation/settings/settings_page.dart';
import 'presentation/settings/edit_name_page.dart';
import 'presentation/settings/edit_email_page.dart';
import 'presentation/settings/edit_search_id_page.dart';
import 'presentation/settings/legal_info_page_alternative.dart';
import 'presentation/presentation_provider.dart';
import 'presentation/splash/splash_screen.dart';
import 'application/auth/auth_state.dart';

/// アプリケーションのエントリーポイント
Future<void> main() async {
  // 環境変数からFlavorを取得
  const flavorString = String.fromEnvironment('FLAVOR');
  const environment = flavorString == 'production'
      ? Environment.production
      : Environment.development;

  await startApp(environment);
}

/// アプリケーションの起動処理
///
/// [environment] 起動する環境
Future<void> startApp(
    [Environment environment = Environment.development,
    List<Override> overrides = const []]) async {
  // Flutterウィジェットバインディングの初期化
  WidgetsFlutterBinding.ensureInitialized();

  // 環境設定の初期化
  AppConfig.initialize(environment);

  // 日本語ロケールの初期化
  await initializeDateFormatting('ja_JP', null);

  // Firebaseの初期化
  await Firebase.initializeApp(
    options: AppConfig.instance.firebaseOptions,
  );

  // AdMobの初期化
  await AdMobService.initialize();

  // アプリケーションの起動
  runApp(
    ProviderScope(
      overrides: overrides,
      child: const MyApp(),
    ),
  );
}

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
    initialLocation: '/splash',
    redirect: (context, state) {
      // スプラッシュ画面の場合はリダイレクトしない
      if (state.location == '/splash') {
        return null;
      }

      return authState.when(
        data: (authState) {
          final isLoggedIn = authState.status == AuthStatus.authenticated;
          final isLoggingIn = state.location == '/login';
          final isSigningUp = state.location == '/signup';

          // 未認証ユーザーのリダイレクト処理
          if (!isLoggedIn && !isLoggingIn && !isSigningUp) {
            return '/login';
          }

          // 認証済みユーザーのリダイレクト処理
          if (isLoggedIn && (isLoggingIn || isSigningUp)) {
            return '/';
          }

          return null;
        },
        loading: () => null,
        error: (_, __) => '/login',
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const BottomNavigationPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
        routes: [
          GoRoute(
            path: 'name',
            builder: (context, state) => const EditNamePage(),
          ),
          GoRoute(
            path: 'email',
            builder: (context, state) => const EditEmailPage(),
          ),
          GoRoute(
            path: 'search-id',
            builder: (context, state) => const EditSearchIdPage(),
          ),
          GoRoute(
            path: 'privacy-policy',
            builder: (context, state) => const LegalInfoPageAlternative(
              title: 'プライバシーポリシー',
              urlPath: 'privacy-policy.html',
            ),
          ),
          GoRoute(
            path: 'terms-of-service',
            builder: (context, state) => const LegalInfoPageAlternative(
              title: '利用規約',
              urlPath: 'terms-of-service.html',
            ),
          ),
        ],
      ),
    ],
  );
});

/// アプリケーションのルートウィジェット
///
/// 設定:
/// - アプリケーションタイトル
/// - テーマ設定
/// - ルーティング設定
///
/// 依存:
/// - [ProviderScope]の子ウィジェットとして使用
/// - [routerProvider]からルーティング設定を取得
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ルーター設定の取得
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'LaKiite',
      theme: AppTheme.theme,
      routerConfig: router,
      // 環境名をデバッグモードで表示
      debugShowCheckedModeBanner: AppConfig.instance.isDevelopment,
    );
  }
}
