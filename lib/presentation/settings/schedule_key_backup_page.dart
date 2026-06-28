import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di/providers.dart';
import '../../application/auth/auth_notifier.dart';
import '../../application/auth/auth_state.dart';
import '../../domain/entity/schedule_encryption.dart';

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
  bool _obscureConfirmPassword = true;
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
      ref.invalidate(schedulePrivateKeyBackupExistsProvider(userId));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('端末引き継ぎ設定を保存しました')),
        );
      }
    } on LocalPrivateKeyMismatchException {
      if (mounted) {
        _showSnackBar('この端末の暗号化キーが現在の公開キーと一致しないため保存できません');
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
    final authState = ref.watch(authNotifierProvider).valueOrNull;
    final userId = authState?.status == AuthStatus.authenticated
        ? authState?.user?.id
        : null;
    final backupStatus = userId == null
        ? const AsyncValue<bool>.data(false)
        : ref.watch(schedulePrivateKeyBackupExistsProvider(userId));
    final hasBackup = backupStatus.valueOrNull ?? false;
    final isLoading = backupStatus.isLoading;
    final hasError = backupStatus.hasError;
    final statusLabel = isLoading
        ? '確認中'
        : hasError
            ? '確認できません'
            : hasBackup
                ? '設定済み'
                : '未設定';
    final description = hasBackup
        ? 'このアカウントには端末引き継ぎ設定が保存されています。新しいパスワードで保存すると、別端末で復元するときに使うパスワードも新しいものに変わります。'
        : '別の端末でも暗号化された予定を表示できるように、秘密キーを引き継ぎパスワードで暗号化して保存します。';
    final passwordLabel = hasBackup ? '新しい引き継ぎパスワード' : '引き継ぎパスワード';
    final buttonLabel = hasBackup ? '引き継ぎパスワードを更新' : '保存';

    return Scaffold(
      appBar: AppBar(
        title: const Text('端末引き継ぎ設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '状態: $statusLabel',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 8),
          const Text(
            '復元パスワードはアプリ内で確認できません。別端末で復元するときに必要になるため、忘れないように保管してください。',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: passwordLabel,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? '引き継ぎパスワードを表示' : '引き継ぎパスワードを非表示',
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
            obscureText: _obscureConfirmPassword,
            decoration: InputDecoration(
              labelText: '確認用パスワード',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                tooltip:
                    _obscureConfirmPassword ? '確認用パスワードを表示' : '確認用パスワードを非表示',
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  );
                },
              ),
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
                : Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}
