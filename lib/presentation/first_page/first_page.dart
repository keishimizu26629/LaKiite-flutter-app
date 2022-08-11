import 'package:flutter/material.dart';

class First_page extends StatelessWidget {
  const First_page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Container(
              child: SizedBox(
                height: 60,
              ),
            ),
            Container(
              child: Container(
                child: Text(
                  'ロゴ',
                ),
                height: 180,
                width: 180,
                alignment: Alignment.center,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 30),
              child: Column(
                children: <Widget>[
                  Text(
                    'アカウントをお持ちの方'
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed:() {},
                      onLongPress: () {},
                      child: const Text('ログイン')
                    ),
                  )
                ]
              ),
              width: double.infinity,
            ),
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: Column(
                children: <Widget>[
                  Text(
                    '初めてご利用の方'
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed:() {},
                      onLongPress: () {},
                      child: const Text('メールアドレスで登録')
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed:() {},
                      onLongPress: () {},
                      child: const Text('Googleで登録')
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 14),
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed:() {},
                      onLongPress: () {},
                      child: const Text('Facebookで登録')
                    ),
                  ),
                ]
              ),
              width: double.infinity,
            ),
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '登録・ログインすることで、',
                      style: TextStyle(color: Color(0xFF333333), fontSize: 12)
                    ),
                    TextSpan(
                      text: '利用規約',
                      style: TextStyle(color: Color(0xFF1a0dab), fontSize: 12)
                    ),
                    TextSpan(
                      text: 'と',
                      style: TextStyle(color: Color(0xFF333333), fontSize: 12)
                    ),
                    TextSpan(
                      text: 'プライバシーポリシー',
                      style: TextStyle(color: Color(0xFF1a0dab), fontSize: 12)
                    ),
                    TextSpan(
                      text: 'に同意したものとみなされます。',
                      style: TextStyle(color: Color(0xFF333333), fontSize: 12)
                    ),
                  ]
                )
              ),
              height: 100,
              width: double.infinity,
            ),
          ],
        ),
      )
    );
  }
}
