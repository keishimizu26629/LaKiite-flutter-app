import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tarakite/domain/entity/user.dart';
import 'package:tarakite/infrastructure/go_router_refresh_notifier.dart';
import 'package:tarakite/presentation/login/login.dart';
import 'package:tarakite/presentation/signup/signup.dart';
import 'package:tarakite/presentation/bottom_navigation/bottom_navigation.dart';
import 'package:tarakite/presentation/splash/splash_screen.dart';
import 'package:tarakite/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import 'presentation/presentation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _router;
  final goRouterRefreshNotifier = GoRouterRefreshNotifier();

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      initialLocation: '/',
      refreshListenable: goRouterRefreshNotifier,
      debugLogDiagnostics: true, // For debugging purposes
      redirect: (context, state) {
        final authState = ref.read(authStateProvider);
        final isLoggedIn = authState.asData?.value != null;
        final isLoggingIn = state.location == '/login' || state.location == '/signup';

        if (!isLoggedIn) {
          return isLoggingIn ? null : '/login';
        } else {
          return isLoggingIn ? '/' : null;
        }
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const BottomNavigation(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupPage(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(child: Text(state.error.toString())),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AppUser?>>(authStateProvider, (previous, next) {
      goRouterRefreshNotifier.notify();
    });

    final authState = ref.watch(authStateProvider);

    return MaterialApp.router(
      title: '予定共有アプリ',
      routerDelegate: _router.routerDelegate,
      routeInformationParser: _router.routeInformationParser,
      routeInformationProvider: _router.routeInformationProvider,
      builder: (context, child) {
        if (authState.isLoading) {
          return const SplashScreen();
        }
        return child!;
      },
    );
  }
}