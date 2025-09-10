import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import '../bottom_navigation/bottom_navigation.dart';
import '../login/login_page.dart';

class SplashScreen extends ConsumerStatefulWidget {
  static const String path = '/splash';

  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 最低限のスプラッシュ表示時間を確保
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted || _hasNavigated) return;

    // 認証状態を確認して画面遷移
    await _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    if (_hasNavigated) return;

    try {
      // 認証状態が確定するまで待機
      final authStateAsync = ref.read(authNotifierProvider);

      await authStateAsync.when(
        data: (authState) async {
          if (!mounted || _hasNavigated) return;

          _hasNavigated = true;

          if (authState.status == AuthStatus.authenticated) {
            context.go(BottomNavigationPage.path);
          } else {
            context.go(LoginPage.path);
          }
        },
        loading: () async {
          // Loading状態の場合は少し待ってからリトライ
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted || _hasNavigated) return;
          _checkAuthAndNavigate();
        },
        error: (error, stackTrace) async {
          // エラーの場合はログイン画面に遷移
          if (!mounted || _hasNavigated) return;

          _hasNavigated = true;
          context.go(LoginPage.path);
        },
      );
    } catch (e) {
      // エラーハンドリング
      if (!mounted || _hasNavigated) return;

      _hasNavigated = true;
      context.go(LoginPage.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 認証状態の変化を監視
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (previous, next) {
      if (_hasNavigated) return;

      next.whenData((state) {
        if (!mounted || _hasNavigated) return;

        _hasNavigated = true;

        if (state.status == AuthStatus.authenticated) {
          context.go(BottomNavigationPage.path);
        } else if (state.status == AuthStatus.unauthenticated) {
          context.go(LoginPage.path);
        }
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFFffa600),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/icon.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
