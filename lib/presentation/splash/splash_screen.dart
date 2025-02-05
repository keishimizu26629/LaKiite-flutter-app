import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tarakite/application/auth/auth_state.dart';
import 'package:tarakite/presentation/presentation_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // 認証状態の初期化を待つ
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    // AuthNotifierの状態を監視
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (previous, next) {
      next.when(
        data: (authState) {
          if (authState.status == AuthStatus.authenticated) {
            context.go('/');
          } else if (authState.status == AuthStatus.unauthenticated) {
            context.go('/login');
          }
        },
        loading: () => null,
        error: (_, __) => null,
      );
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 200,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.calendar_today,
                  size: 100,
                  color: Colors.blue,
                );
              },
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              '予定共有アプリ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
