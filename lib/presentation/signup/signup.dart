import 'package:flutter/material.dart';

class Signup_page extends StatefulWidget {
  const Signup_page({Key? key}) : super(key: key);

  @override
  State<Signup_page> createState() => _Signup_pageState();
}

class _Signup_pageState extends State<Signup_page> {
  final _userName = TextEditingController();
  final _emailAdress = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('会員登録', style: TextStyle(color: Colors.white)),
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
                        'ニックネーム',
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF555555))
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: TextFormField(
                          controller: _userName,
                          textAlign: TextAlign.start,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '〇〇〇〇〇',
                            hintStyle: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF888888),
                            )
                          )
                        ),
                      ),
                    )
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Column(children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '生年月日',
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF555555))
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: TextFormField(
                            controller: _password,
                            textAlign: TextAlign.start,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'xxxx/xx/xx',
                              hintStyle: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF888888),
                              )
                            )
                          ),
                        ),
                      )
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Column(children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'メールアドレス',
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF555555))
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: TextFormField(
                            controller: _emailAdress,
                            textAlign: TextAlign.start,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'xxxxxxxxxx@xxxxx.xxx',
                              hintStyle: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF888888),
                              )
                            )
                          ),
                        ),
                      )
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Column(children: <Widget>[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'パスワード',
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(color: Color(0xFF555555))
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: TextFormField(
                            controller: _password,
                            textAlign: TextAlign.start,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '●●●●●●●●●●●●●●●●',
                              hintStyle: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF888888),
                              )
                            )
                          ),
                        ),
                      )
                    ]),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 40),
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {},
                      onLongPress: () {},
                      child: const Text(
                        '登録する',
                        style: TextStyle(color: Color(0xFF1a0dab)),
                      )),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 24),
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
            ),
          ])));
  }
}
