import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditEmailPage extends ConsumerStatefulWidget {
  static const String path = 'email';

  const EditEmailPage({super.key});

  @override
  ConsumerState<EditEmailPage> createState() => _EditEmailPageState();
}

class _EditEmailPageState extends ConsumerState<EditEmailPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
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
        _errorText = 'メールアドレスを入力してください';
      });
      return;
    }

    if (!RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[\w-]{2,}$')
        .hasMatch(newEmail)) {
      setState(() {
        _errorText = '有効なメールアドレスを入力してください';
      });
      return;
    }

    if (password.isEmpty) {
      setState(() {
        _errorText = '現在のパスワードを入力してください';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
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
        _errorText = switch (e.code) {
          'wrong-password' => 'パスワードが間違っています',
          'email-already-in-use' => 'このメールアドレスは既に使用されています',
          'invalid-email' => '無効なメールアドレスです',
          'requires-recent-login' => '再認証が必要です',
          _ => 'エラーが発生しました: ${e.message}',
        };
      });
    } catch (e) {
      setState(() {
        _errorText = 'エラーが発生しました: $e';
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
              controller: _emailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例：example@example.com',
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
              controller: _passwordController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                errorText: _errorText,
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
