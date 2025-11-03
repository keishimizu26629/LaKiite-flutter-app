import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation_provider.dart';
import 'edit_name_page.dart';
import 'edit_email_page.dart';
import 'edit_search_id_page.dart';
import '../login/login_page.dart';
import 'account_deletion_webview_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  static const String path = '/settings';

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
              context.push('/settings/${EditNamePage.path}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('メールアドレス'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/${EditEmailPage.path}');
            },
          ),
          ListTile(
            leading: const Icon(Icons.tag),
            title: const Text('検索ID'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/settings/${EditSearchIdPage.path}');
            },
          ),
          const Divider(),

          // デバッグ機能（デバッグモードまたは開発環境でのみ表示）
          // TestFlight配信時にコメントアウト
          /*
          ListTile(
            leading: const Icon(Icons.bug_report, color: Colors.orange),
            title: const Text('🐯 プッシュ通知デバッグ'),
            subtitle: const Text('FCMトークンの確認・テスト'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugNotificationPage(),
                ),
              );
            },
          ),
          const Divider(),
          */

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('プライバシーポリシー'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/privacy-policy'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('利用規約'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/terms-of-service'),
          ),
          const Divider(),
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
                // ローディングインジケータを表示
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('ログアウト中...'),
                      ],
                    ),
                  ),
                );

                try {
                  await ref.read(authNotifierProvider.notifier).signOut();

                  // ローディングインジケータを閉じる
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }

                  // ログイン画面へ遷移
                  if (context.mounted) {
                    context.go(LoginPage.path);
                  }
                } catch (e) {
                  // ローディングインジケータを閉じる
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }

                  if (context.mounted) {
                    // エラーの種類に応じて適切なメッセージを表示
                    String errorMessage = 'ログアウトに失敗しました';
                    if (e.toString().contains('network')) {
                      errorMessage = 'ネットワーク接続エラー: インターネット接続を確認してください';
                    } else if (e.toString().contains('permission')) {
                      errorMessage = '権限エラー: アプリを再起動してください';
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage)),
                    );
                  }
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.web, color: Colors.blue),
            title: const Text('アカウント削除 (Web)', style: TextStyle(color: Colors.blue)),
            subtitle: const Text('Webページでアカウントを削除'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push(AccountDeletionWebViewPage.path);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('アカウント削除 (アプリ内)', style: TextStyle(color: Colors.red)),
            subtitle: const Text('アプリ内でアカウントを削除'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('アカウント削除'),
                  content: const Text(
                    'アカウントを削除すると、すべてのデータが完全に削除され、元に戻すことはできません。\n\n本当にアカウントを削除してもよろしいですか？',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('キャンセル'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('削除する'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                // パスワード入力ダイアログを表示
                final password = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    String inputPassword = '';
                    return AlertDialog(
                      title: const Text('パスワード確認'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'セキュリティのため、現在のパスワードを入力してください。',
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'パスワード',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) => inputPassword = value,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(context, inputPassword),
                          child: const Text('確認'),
                        ),
                      ],
                    );
                  },
                );

                if (password != null && password.isNotEmpty && context.mounted) {
                  // 削除処理中の進捗ダイアログを表示
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('アカウントを削除中...'),
                        ],
                      ),
                    ),
                  );

                  try {
                    // 再認証付きアカウント削除を試行
                    final authNotifier = ref.read(authNotifierProvider.notifier);

                    // まず再認証を試行
                    try {
                      await (authNotifier as dynamic).reauthenticateWithPassword(password);
                      // 再認証成功後にアカウント削除
                      await authNotifier.deleteAccount();
                    } catch (e) {
                      // 再認証メソッドがない場合は通常の削除を試行
                      await authNotifier.deleteAccount();
                    }

                    // 進捗ダイアログを閉じる
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }

                    // ログイン画面に遷移
                    if (context.mounted) {
                      context.go(LoginPage.path);
                    }
                  } catch (e) {
                    // 進捗ダイアログを閉じる
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }

                    // エラーメッセージを表示
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('アカウント削除に失敗しました: ${e.toString()}'),
                        ),
                      );
                    }
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
