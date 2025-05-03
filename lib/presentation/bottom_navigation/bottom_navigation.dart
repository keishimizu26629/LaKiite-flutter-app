import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/home_page.dart';
import '../friend/friend_list_page.dart';
import '../my_page/my_page.dart';

class BottomNavigationPage extends ConsumerStatefulWidget {
  static const String path = '/';

  const BottomNavigationPage({super.key});

  @override
  ConsumerState<BottomNavigationPage> createState() =>
      _BottomNavigationPageState();
}

class _BottomNavigationPageState extends ConsumerState<BottomNavigationPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(key: PageStorageKey('home_page')),
    const FriendListPage(key: PageStorageKey('friend_list_page')),
    const MyPage(key: PageStorageKey('my_page')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'ホーム',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_3_outlined),
              activeIcon: Icon(Icons.groups_3),
              label: 'フレンド',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'マイページ',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
