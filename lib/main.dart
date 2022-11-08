import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import './presentation/signup/signup.dart';
import 'presentation/login/login.dart';
import './presentation/bottom_navigation/bottom_navigation.dart';
import './infrastructure/authRepository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ProviderScope(
      child: App(),
    ),
  );
}

class App extends ConsumerWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const appName = 'アプリテーマ';
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
        title: appName,
        theme: ThemeData(
          // brightness: Brightness.dark,
          primaryColor: Color.fromARGB(255, 255, 125, 227),
          fontFamily: 'Quicksand',
          textTheme: const TextTheme(
            headline1: TextStyle(fontSize: 32, fontStyle: FontStyle.italic),
            bodyText2: TextStyle(fontSize: 14, fontFamily: 'Hind'),
          ),
        ),
        home: authState.when(
            data: (data) {
              if (data != null) {
                return const BottomNavigationPage();
              }
              return const SignIn_page();
            },
            error: (Object error, StackTrace? stackTrace) {},
            loading: () {}));
  }
}
