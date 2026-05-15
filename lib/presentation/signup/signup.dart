import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation_provider.dart';
import '../../utils/logger.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});
  static const String path = '/signup';

  @override
  ConsumerState<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_isLoading) return;

    AppLogger.debugOnly('SignupPage._handleSignup開始');
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signUp(
            _emailController.text,
            _passwordController.text,
            _nameController.text,
            displayName: _displayNameController.text.isNotEmpty
                ? _displayNameController.text
                : null,
          );
      final authState = ref.read(authNotifierProvider);
      AppLogger.debugOnly('SignupPage._handleSignup後 state=$authState');
      if (mounted && authState.hasError) {
        final error = authState.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('サインアップに失敗しました: ${error.toString()}')),
        );
      }
    } catch (e) {
      AppLogger.errorOnly('SignupPage._handleSignup例外', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('サインアップに失敗しました: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '名前(フルネーム)',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: '表示名(ニックネーム)',
                  border: OutlineInputBorder(),
                  helperText: '空白の場合は名前が表示名として使用されます',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'パスワード',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('新規登録'),
              ),
              // Firstリリースではサードパーティー登録を非表示
              // const SizedBox(height: 16),
              // OutlinedButton(
              //   onPressed: null,
              //   style: OutlinedButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(vertical: 16),
              //   ),
              //   child: const Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Icon(Icons.g_mobiledata),
              //       SizedBox(width: 8),
              //       Text('Googleで登録'),
              //     ],
              //   ),
              // ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _navigateToLogin,
                child: const Text('すでにアカウントをお持ちの方はログイン'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
