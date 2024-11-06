import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'signup_view_model.dart';
import 'package:go_router/go_router.dart';

class SignupPage extends ConsumerWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(signupViewModelProvider.notifier);
    final state = ref.watch(signupViewModelProvider);

    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final userIdController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: userIdController,
              decoration: const InputDecoration(labelText: 'ユーザーID（8文字以上）'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'メールアドレス'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'パスワード'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            state.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () {
                      viewModel.signUp(
                        emailController.text,
                        passwordController.text,
                        userIdController.text,
                      );
                    },
                    child: const Text('登録'),
                  ),
            TextButton(
              onPressed: () {
                context.go('/login');
              },
              child: const Text('ログイン画面に戻る'),
            ),
          ],
        ),
      ),
    );
  }
}