import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TimelinePage extends ConsumerWidget {
  const TimelinePage({Key? key}) : super(key: key);

  // タイムラインを表示するウィジェット
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // イベントリストの取得は省略

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('タイムライン'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '一覧'),
              Tab(text: 'カレンダー'),
              Tab(text: 'マップ'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // 一覧表示
            Center(child: Text('一覧表示')),
            // カレンダー表示
            Center(child: Text('カレンダー表示')),
            // マップ表示
            Center(child: Text('マップ表示')),
          ],
        ),
      ),
    );
  }
}