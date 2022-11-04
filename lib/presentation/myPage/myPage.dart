import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MyPage extends ConsumerWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        appBar: AppBar(
            title: Text('マイページ'),
            centerTitle: true,
            backgroundColor: Theme.of(context).primaryColor),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Row(children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ListTile(
                        title: Text('Musashi', style: TextStyle(fontSize: 24)),
                        subtitle:
                            Text('1992/02/26', style: TextStyle(fontSize: 18))),
                  ),
                )
              ]),
              Container(
                margin: EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 40,
                          width: 60,
                          child: Divider(
                            color: Colors.grey,
                            thickness: 1,
                          ),
                        ),
                        Text(
                          '  Account Info.  ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          )
                        ),
                        SizedBox(
                          height: 40,
                          width: 60,
                          child: Divider(
                            color: Colors.grey,
                            thickness: 1,
                          ),
                        ),
                      ]
                    ),
                    Container(

                      child: ListTile(
                        title:
                            Text('Email Address', style: TextStyle(fontSize: 20)),
                        subtitle: Text('testtest@gmail.com',
                            style: TextStyle(fontSize: 18))))
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 40,
                          width: 60,
                          child: Divider(
                            color: Colors.grey,
                            thickness: 1,
                          ),
                        ),
                        Text(
                          '  Group  ',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          )
                        ),
                        SizedBox(
                          height: 40,
                          width: 60,
                          child: Divider(
                            color: Colors.grey,
                            thickness: 1,
                          ),
                        ),
                      ]
                    ),
                    Container(
                      child: ListTile(
                        title:
                            Text('Not belonging to any group yet.', style: TextStyle(fontSize: 20)),
                      ))
                  ],
                ),
              ),
            ])));
  }
}
