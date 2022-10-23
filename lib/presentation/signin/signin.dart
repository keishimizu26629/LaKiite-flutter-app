import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import './signin_view_model.dart';

class SignIn_page extends ConsumerWidget {
  const SignIn_page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(signInViewModelProvider);

    final FirebaseAuth auth = FirebaseAuth.instance;

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
                child: Column(
                  children: [
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
                              border: Border.all(color: Color(0xFF555555))),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: TextFormField(
                                controller: vm.emailAddressController,
                                textAlign: TextAlign.start,
                                decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'xxxxxxxxxx@xxxxx.xxx',
                                    hintStyle: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF888888),
                                    ))),
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
                              border: Border.all(color: Color(0xFF555555))),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: TextFormField(
                              controller: vm.passwordController,
                              textAlign: TextAlign.start,
                              decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '●●●●●●●●●●●●●●●●',
                                  hintStyle: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF888888),
                                  )),
                              obscureText: true,
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
                          onPressed: () {
                            vm.signIn();
                          },
                          onLongPress: () {},
                          child: const Text(
                            'ログイン',
                            style: TextStyle(color: Color(0xFF1a0dab)),
                          )),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: RichText(
                          text: TextSpan(children: [
                        TextSpan(
                            text: 'パスワードを忘れた方は',
                            style: TextStyle(
                                color: Color(0xFF555555), fontSize: 12)),
                        TextSpan(
                            text: 'こちら',
                            style: TextStyle(
                                color: Color(0xFF1a0dab), fontSize: 12)),
                      ])),
                      height: 100,
                      width: double.infinity,
                    ),
                    Container(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Container(
                            width: 100,
                            child: Divider(
                              color: Color(0xFF333333),
                              thickness: 1,
                              height: 0,
                            ),
                          ),
                          Text('または'),
                          Container(
                            width: 100,
                            child: Divider(
                              color: Color(0xFF333333),
                              thickness: 1,
                              height: 0,
                            ),
                          ),
                    ])),
                    Container(
                      margin: const EdgeInsets.only(top: 40),
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                          onPressed: () {

                          },
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
                          onPressed: () {

                          },
                          onLongPress: () {},
                          child: const Text(
                            'Facebookでログイン',
                            style: TextStyle(color: Color(0xFF1a0dab)),
                          )),
                    ),
                    Container(
                      alignment: Alignment.center,
                      child: RichText(
                          text: TextSpan(children: [
                        TextSpan(
                            text: '新規登録の方はこちら',
                            style: TextStyle(
                                color: Color(0xFF1a0dab), fontSize: 12)),
                      ])),
                      height: 100,
                      width: double.infinity,
                    ),
                  ],
                ),
              ),
            ])));
  }
}
