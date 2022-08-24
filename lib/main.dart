import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import './presentation/first_page/first_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}

class MyApp extends HookConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const appName = 'アプリテーマ';

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
        home: First_page());
  }
}
