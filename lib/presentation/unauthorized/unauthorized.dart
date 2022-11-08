import 'package:flutter/material.dart';

class Unauthorized extends StatelessWidget {
  const Unauthorized({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(child: Container(child: const Text('メールを認証してください。'))));
  }
}
