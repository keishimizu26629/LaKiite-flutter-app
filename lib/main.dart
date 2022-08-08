import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      home: Text('test')
    );
  }
}
