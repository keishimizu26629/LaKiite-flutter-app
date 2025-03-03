import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/presentation/presentation_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

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
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    authState.whenData((state) {
      if (!mounted) return;
      if (state.status == AuthStatus.authenticated) {
        context.go('/');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (previous, next) {
      next.whenData((state) {
        if (!mounted) return;
        if (state.status == AuthStatus.authenticated) {
          context.go('/');
        } else if (state.status == AuthStatus.unauthenticated) {
          context.go('/login');
        }
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFFffa600),
      body: Center(
        child: Image.asset(
          'assets/icon/icon.png',
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}
