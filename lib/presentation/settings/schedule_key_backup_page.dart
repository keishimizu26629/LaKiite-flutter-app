import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di/providers.dart';
import '../../application/auth/auth_notifier.dart';
import '../../application/auth/auth_state.dart';

class ScheduleKeyBackupPage extends ConsumerStatefulWidget {
  const ScheduleKeyBackupPage({super.key});

  static const String path = 'schedule-key-backup';

  @override
  ConsumerState<ScheduleKeyBackupPage> createState() =>
      _ScheduleKeyBackupPageState();
}

class _ScheduleKeyBackupPageState extends ConsumerState<ScheduleKeyBackupPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    final userId = authState?.status == AuthStatus.authenticated
        ? authState?.user?.id
        : null;
    if (userId == null) {
      return;
    }

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    if (password.isEmpty) {
      _showSnackBar('引き継ぎパスワードを入力してください');
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('確認用パスワードが一致しません');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(scheduleEncryptionServiceProvider).createPrivateKeyBackup(
            uid: userId,
            password: password,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('端末引き継ぎ設定を保存しました')),
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('端末引き継ぎ設定を保存できませんでした');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('端末引き継ぎ設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '別の端末でも暗号化された予定を表示できるように、秘密キーを引き継ぎパスワードで暗号化して保存します。',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: '引き継ぎパスワード',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? '表示' : '非表示',
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPasswordController,
            obscureText: _obscurePassword,
            decoration: const InputDecoration(
              labelText: '確認用パスワード',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _save,
            child: _isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
    );
  }
}
