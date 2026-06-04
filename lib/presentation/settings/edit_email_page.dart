import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditEmailPage extends ConsumerStatefulWidget {
  const EditEmailPage({super.key});
  static const String path = 'email';

  @override
  ConsumerState<EditEmailPage> createState() => _EditEmailPageState();
}

class _EditEmailPageState extends ConsumerState<EditEmailPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailErrorText;
  String? _passwordErrorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _emailController.text = user.email ?? '';
      }
    } catch (_) {
      // Firebase未初期化のテスト環境では空欄のまま表示する。
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updateEmail() async {
    final newEmail = _emailController.text.trim();
    final password = _passwordController.text;

    if (newEmail.isEmpty) {
      setState(() {
        _emailErrorText = 'メールアドレスを入力してください';
        _passwordErrorText = null;
      });
      return;
    }

    if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[\w-]{2,}$')
        .hasMatch(newEmail)) {
      setState(() {
        _emailErrorText = '有効なメールアドレスを入力してください';
        _passwordErrorText = null;
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _emailErrorText = null;
        _passwordErrorText = '現在のパスワードを入力してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _emailErrorText = null;
      _passwordErrorText = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('ユーザーが見つかりません');

      // 現在のメールアドレスと同じ場合は更新不要
      if (user.email == newEmail) {
        Navigator.pop(context);
        return;
      }

      // 再認証
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // メールアドレスの更新
      await user.verifyBeforeUpdateEmail(newEmail);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('確認メールを送信しました。メール内のリンクをクリックして変更を完了してください。'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _emailErrorText = 'このメールアドレスは既に使用されています';
            _passwordErrorText = null;
            break;
          case 'invalid-email':
            _emailErrorText = '無効なメールアドレスです';
            _passwordErrorText = null;
            break;
          case 'wrong-password':
            _emailErrorText = null;
            _passwordErrorText = 'パスワードが間違っています';
            break;
          case 'requires-recent-login':
            _emailErrorText = null;
            _passwordErrorText = '再認証が必要です';
            break;
          default:
            _emailErrorText = null;
            _passwordErrorText = 'エラーが発生しました: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        _emailErrorText = null;
        _passwordErrorText = 'エラーが発生しました: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メールアドレスの設定'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateEmail,
            child: const Text('保存'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            key: const Key('edit-email-bottom-save-button'),
            onPressed: _isLoading ? null : _updateEmail,
            child: const Text('保存'),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '新しいメールアドレス',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('edit-email-email-field'),
              controller: _emailController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: '例：example@example.com',
                errorText: _emailErrorText,
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            const Text(
              '現在のパスワード',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('edit-email-password-field'),
              controller: _passwordController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                errorText: _passwordErrorText,
              ),
              obscureText: true,
              enabled: !_isLoading,
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 16),
            const Text(
              'メールアドレスを変更すると、確認メールが送信されます。\nメール内のリンクをクリックして変更を完了してください。',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
