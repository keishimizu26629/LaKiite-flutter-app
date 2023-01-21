import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/services.dart';

import './signup_view_model.dart';

// ignore: camel_case_types
class SignUp_page extends ConsumerWidget {
  const SignUp_page({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(signUpViewModelProvider);

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
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'ニックネーム',
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF555555))),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: TextFormField(
                              controller: vm.userNameController,
                              textAlign: TextAlign.start,
                              textAlignVertical: TextAlignVertical.center,
                              decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '〇〇〇〇〇',
                                  hintStyle: TextStyle(
                                    fontSize: 18,
                                    color: Color(0xFF888888),
                                  ))),
                        ),
                      )
                    ]),
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Column(children: <Widget>[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '生年月日',
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF555555))),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: TextFormField(
                                controller: vm.dateOfBirthController,
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(8),
                                ],
                                decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    hintText: '19900125',
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
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'メールアドレス',
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF555555))),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: TextFormField(
                                controller: vm.emailAddressController,
                                textAlign: TextAlign.start,
                                keyboardType: TextInputType.emailAddress,
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
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'パスワード',
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF555555))),
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
                            vm.signUp();
                          },
                          onLongPress: () {},
                          child: const Text(
                            '登録する',
                            style: TextStyle(color: Color(0xFF1a0dab)),
                          )),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 24),
                      height: 50,
                      width: double.infinity,
                      child: RichText(
                          // ignore: prefer_const_literals_to_create_immutables
                          text: const TextSpan(children: [
                        TextSpan(
                            text: '登録・ログインすることで、',
                            style: TextStyle(
                                color: Color(0xFF333333), fontSize: 12)),
                        TextSpan(
                            text: '利用規約',
                            style: TextStyle(
                                color: Color(0xFF1a0dab), fontSize: 12)),
                        TextSpan(
                            text: 'と',
                            style: TextStyle(
                                color: Color(0xFF333333), fontSize: 12)),
                        TextSpan(
                            text: 'プライバシーポリシー',
                            style: TextStyle(
                                color: Color(0xFF1a0dab), fontSize: 12)),
                        TextSpan(
                            text: 'に同意したものとみなされます。',
                            style: TextStyle(
                                color: Color(0xFF333333), fontSize: 12)),
                      ])),
                    ),
                    Container(
                      alignment: Alignment.center,
                      // ignore: sort_child_properties_last
                      child: RichText(
                          text: TextSpan(children: [
                        TextSpan(
                            text: 'ログインの方はこちら',
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                vm.toLogin(context: context);
                              },
                            style: const TextStyle(
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
