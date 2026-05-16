import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/home_page.dart';
import '../friend/friend_list_page.dart';
import '../my_page/my_page.dart';
import '../widgets/auth_dependent_builder.dart';

class BottomNavigationPage extends ConsumerStatefulWidget {
  const BottomNavigationPage({super.key});
  static const String path = '/';

  @override
  ConsumerState<BottomNavigationPage> createState() =>
      _BottomNavigationPageState();
}

class _BottomNavigationPageState extends ConsumerState<BottomNavigationPage> {
  @override
  Widget build(BuildContext context) {
    return AuthDependentBuilder(
      onAuthenticated: (_) => const _AuthenticatedBottomNavigationShell(),
      onLoading: (_) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      onUnauthenticated: (_) => const Scaffold(
        body: SizedBox.shrink(),
      ),
    );
  }
}

class _AuthenticatedBottomNavigationShell extends StatefulWidget {
  const _AuthenticatedBottomNavigationShell();

  @override
  State<_AuthenticatedBottomNavigationShell> createState() =>
      _AuthenticatedBottomNavigationShellState();
}

class _AuthenticatedBottomNavigationShellState
    extends State<_AuthenticatedBottomNavigationShell> {
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
              color: Colors.black.withValues(alpha: 0.1),
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
