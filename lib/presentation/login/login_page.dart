import 'package:flutter/material.dart';

class Login_page extends StatefulWidget {
  const Login_page({Key? key}) : super(key: key);

  @override
  State<Login_page> createState() => _Login_pageState();
}

class _Login_pageState extends State<Login_page> {
  final _emailAddress = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('ログイン', style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
          margin: const EdgeInsets.all(20),
          child: Column(children: <Widget>[
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: Column(
                children: [
                  Column(children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'メールアドレス',
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 10),
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF555555))
                      ),
                      child: TextFormField(
                        controller: _emailAddress,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'xxxxxxxxxx@xxxxx.xxx',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF888888),
                          )
                        )
                      ),
                    )
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Column(children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'パスワード',
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 10),
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF555555))
                        ),
                        child: TextFormField(
                          controller: _password,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '●●●●●●●●●●●●●●●●',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                            )
                          )
                        ),
                      )
                    ]),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 28),
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {},
                      onLongPress: () {},
                      child: const Text(
                        'ログイン',
                        style: TextStyle(color: Color(0xFF1a0dab)),
                      )),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    child: RichText(text: TextSpan(children: [
                      TextSpan(
                        text: 'パスワードを忘れた方は',
                        style: TextStyle(color: Color(0xFF333333), fontSize: 12)
                      ),
                      TextSpan(
                        text: 'こちら',
                        style: TextStyle(color: Color(0xFF1a0dab), fontSize: 12)
                      ),
                    ])),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        color: Color(0xFF333333)
                      )
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 10, bottom: 10, left: 30, right: 30),
                    child: Text('または'),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        color: Color(0xFF333333)
                      )
                    ),
                  ),
                ]
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10),
              child: Column(children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                      onPressed: () {},
                      onLongPress: () {},
                      child: const Text(
                        'Googleでログイン',
                        style: TextStyle(color: Color(0xFF1a0dab)),
                      )),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                      onPressed: () {},
                      onLongPress: () {},
                      child: const Text(
                        'Facebookでログイン',
                        style: TextStyle(color: Color(0xFF1a0dab)),
                      )),
                ),
              ]),
              width: double.infinity,
            ),
            Container(
              margin: EdgeInsets.only(top: 28),
              child: RichText(text: TextSpan(children: [
                TextSpan(
                  text: '新規登録はこちら',
                  style: TextStyle(color: Color(0xFF1a0dab), fontSize: 12)
                ),
              ])),
            ),
          ])));
  }
}
