import 'package:flutter/material.dart';

// ignore: camel_case_types
class First_page extends StatelessWidget {
  const First_page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
      margin: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          const SizedBox(
            height: 60,
          ),
          Container(
            height: 180,
            width: 180,
            alignment: Alignment.center,
            color: Theme.of(context).primaryColor,
            child: const Text(
              'ロゴ',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 30),
            width: double.infinity,
            child: Column(children: <Widget>[
              const Text('アカウントをお持ちの方'),
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                    onPressed: () {},
                    onLongPress: () {},
                    child: const Text('ログイン')),
              )
            ]),
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            width: double.infinity,
            child: Column(children: <Widget>[
              const Text('初めてご利用の方'),
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                    onPressed: () {},
                    onLongPress: () {},
                    child: const Text('メールアドレスで登録')),
              ),
              Container(
                margin: const EdgeInsets.only(top: 14),
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                    onPressed: () {},
                    onLongPress: () {},
                    child: const Text('Googleで登録')),
              ),
              Container(
                margin: const EdgeInsets.only(top: 14),
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                    onPressed: () {},
                    onLongPress: () {},
                    child: const Text('Facebookで登録')),
              ),
            ]),
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            height: 100,
            width: double.infinity,
            child: RichText(
                text: const TextSpan(
                    // ignore: prefer_const_literals_to_create_immutables
                    children: [
                  TextSpan(
                      text: '登録・ログインすることで、',
                      style: TextStyle(color: Color(0xFF333333), fontSize: 12)),
                  TextSpan(
                      text: '利用規約',
                      style: TextStyle(color: Color(0xFF1a0dab), fontSize: 12)),
                  TextSpan(
                      text: 'と',
                      style: TextStyle(color: Color(0xFF333333), fontSize: 12)),
                  TextSpan(
                      text: 'プライバシーポリシー',
                      style: TextStyle(color: Color(0xFF1a0dab), fontSize: 12)),
                  TextSpan(
                      text: 'に同意したものとみなされます。',
                      style: TextStyle(color: Color(0xFF333333), fontSize: 12)),
                ])),
          ),
        ],
      ),
    ));
  }
}
