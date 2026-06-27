import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../home/home_page.dart';
import '../friend/friend_list_page.dart';
import '../encryption/schedule_private_key_gate.dart';
import '../list/list_page.dart';
import '../my_page/my_page.dart';
import '../widgets/auth_dependent_builder.dart';
import '../../infrastructure/how_to_use_prompt_preferences.dart';
import '../../infrastructure/deep_link_navigation_service.dart';
import '../../infrastructure/notification_navigation_service.dart';
import 'package:lakiite/app/di/providers.dart';

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
    final encryptionService = ref.watch(scheduleEncryptionServiceProvider);

    return AuthDependentBuilder(
      onAuthenticated: (userId) => SchedulePrivateKeyGate(
        userId: userId,
        encryptionService: encryptionService,
        child: const _AuthenticatedBottomNavigationShell(),
      ),
      onLoading: (_) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      onUnauthenticated: (_) => const Scaffold(body: SizedBox.shrink()),
    );
  }
}

class _AuthenticatedBottomNavigationShell extends ConsumerStatefulWidget {
  const _AuthenticatedBottomNavigationShell();

  @override
  ConsumerState<_AuthenticatedBottomNavigationShell> createState() =>
      _AuthenticatedBottomNavigationShellState();
}

class _AuthenticatedBottomNavigationShellState
    extends ConsumerState<_AuthenticatedBottomNavigationShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(key: PageStorageKey('home_page')),
    const FriendListPage(key: PageStorageKey('friend_list_page')),
    const ListPage(key: PageStorageKey('list_page')),
    const MyPage(key: PageStorageKey('my_page')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      NotificationNavigationService.instance.markNavigationReady();
      final didOpenDeepLink =
          await DeepLinkNavigationService.instance.markNavigationReady();
      if (!mounted || didOpenDeepLink) return;
      unawaited(_showHowToUsePromptIfNeeded());
    });
  }

  Future<void> _showHowToUsePromptIfNeeded() async {
    final preferences = ref.read(howToUsePromptPreferencesProvider);
    final shouldShowPrompt = await preferences.shouldShowPrompt();

    if (!shouldShowPrompt || !mounted) {
      return;
    }

    final openGuide = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('LaKiiteの使い方'),
        content: const Text('はじめに、予定の共有やフレンド追加の流れを確認しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('閉じる'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('使い方を見る'),
          ),
        ],
      ),
    );

    await preferences.markPromptSeen();

    if (openGuide == true && mounted) {
      context.push('/settings/how-to-use');
    }
  }

  @override
  void dispose() {
    NotificationNavigationService.instance.markNavigationNotReady();
    DeepLinkNavigationService.instance.markNavigationNotReady();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
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
          unselectedLabelStyle: const TextStyle(fontSize: 12),
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
              icon: Icon(Icons.format_list_bulleted_outlined),
              activeIcon: Icon(Icons.format_list_bulleted),
              label: 'リスト',
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
