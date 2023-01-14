// ignore: file_names
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import './myPage_view_model.dart';

class MyPage extends ConsumerWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(myPageViewModelProvider);
    final auth = FirebaseAuth.instance;
    return Scaffold(
        appBar: AppBar(
            title: const Text('マイページ'),
            centerTitle: true,
            backgroundColor: Theme.of(context).primaryColor),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // ignore: prefer_const_literals_to_create_immutables
              Row(children: [
                const CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey,
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: ListTile(
                        title: Text('Musashi', style: TextStyle(fontSize: 24)),
                        subtitle:
                            Text('1992/02/26', style: TextStyle(fontSize: 18))),
                  ),
                )
              ]),
              Container(
                margin: const EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    // ignore: prefer_const_literals_to_create_immutables
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const SizedBox(
                        height: 40,
                        width: 60,
                        child: Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                      ),
                      const Text('  Account Info.  ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(
                        height: 40,
                        width: 60,
                        child: Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                      ),
                    ]),
                    const ListTile(
                        title: Text('Email Address',
                            style: TextStyle(fontSize: 20)),
                        subtitle: Text('testtest@gmail.com',
                            style: TextStyle(fontSize: 18)))
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    // ignore: prefer_const_literals_to_create_immutables
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const SizedBox(
                        height: 40,
                        width: 60,
                        child: Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                      ),
                      const Text('  Group  ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          )),
                      const SizedBox(
                        height: 40,
                        width: 60,
                        child: Divider(
                          color: Colors.grey,
                          thickness: 1,
                        ),
                      ),
                    ]),
                    const ListTile(
                      title: Text('Not belonging to any group yet.',
                      style: TextStyle(fontSize: 20)),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 40),
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                          onPressed: () {
                            vm.logout();
                          },
                          onLongPress: () {},
                          child: const Text(
                            'ログアウト',
                            style: TextStyle(color: Color(0xFF1a0dab)),
                          )),
                    ),
                  ],
                ),
              ),
            ])));
  }
}
