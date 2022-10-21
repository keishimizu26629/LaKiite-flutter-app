import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final selectedIndex = StateProvider((ref) => 0);

class BottomNavigationPage extends ConsumerWidget {
  const BottomNavigationPage({Key? key}) : super(key: key);
  final List<Widget> _tabs = const [
    Center(child: Text('タイムライン')),
    Center(child: Text('カレンダー')),
    Center(child: Text('マイページ')),
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _selectedIndex = ref.watch(selectedIndex.state);
    return Scaffold(
        body: _tabs[_selectedIndex.state],
        bottomNavigationBar: BottomNavigationBar(
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            selectedItemColor: Colors.black,
            currentIndex: _selectedIndex.state,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'タイムライン',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'カレンダー',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'マイページ',
              ),
            ],
            onTap: (int index) {
              _selectedIndex.state = index;
            }));
  }
}
