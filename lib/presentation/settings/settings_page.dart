import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('名前'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/name');
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('メールアドレス'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/email');
            },
          ),
          ListTile(
            leading: const Icon(Icons.tag),
            title: const Text('検索ID'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/search-id');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ログアウト'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ログアウト'),
                  content: const Text('ログアウトしてもよろしいですか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('ログアウト'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                try {
                  await ref.read(authNotifierProvider.notifier).signOut();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ログアウトに失敗しました')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
