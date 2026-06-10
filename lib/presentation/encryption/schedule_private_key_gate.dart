import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/auth/auth_notifier.dart';
import 'package:lakiite/domain/entity/schedule_encryption.dart';
import 'package:lakiite/infrastructure/encryption/schedule_encryption_service.dart';
import '../login/login_page.dart';

class SchedulePrivateKeyGate extends ConsumerStatefulWidget {
  const SchedulePrivateKeyGate({
    super.key,
    required this.userId,
    required this.encryptionService,
    required this.child,
  });

  final String userId;
  final ScheduleEncryptionService encryptionService;
  final Widget child;

  @override
  ConsumerState<SchedulePrivateKeyGate> createState() =>
      _SchedulePrivateKeyGateState();
}

class _SchedulePrivateKeyGateState
    extends ConsumerState<SchedulePrivateKeyGate> {
  late Future<SchedulePrivateKeySetupStatus> _statusFuture;
  bool _showRestoreForm = false;

  @override
  void initState() {
    super.initState();
    _statusFuture = _loadStatus();
  }

  @override
  void didUpdateWidget(covariant SchedulePrivateKeyGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _showRestoreForm = false;
      _statusFuture = _loadStatus();
    }
  }

  Future<SchedulePrivateKeySetupStatus> _loadStatus() {
    return widget.encryptionService.currentUserPrivateKeyStatus(widget.userId);
  }

  Future<void> _signOutToLogin() async {
    await ref.read(authNotifierProvider.notifier).signOut();
    if (mounted) {
      context.go(LoginPage.path);
    }
  }

  void _reloadStatus() {
    setState(() {
      _showRestoreForm = false;
      _statusFuture = _loadStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SchedulePrivateKeySetupStatus>(
      future: _statusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _KeyGateMessageScaffold(
            title: '暗号化キーを確認できません',
            message: '通信状況を確認してから、もう一度ログインしてください。',
            actionLabel: 'ログイン画面へ',
            onAction: _signOutToLogin,
          );
        }

        switch (snapshot.data) {
          case SchedulePrivateKeySetupStatus.ready:
          case SchedulePrivateKeySetupStatus.notStarted:
            return widget.child;
          case SchedulePrivateKeySetupStatus.restoreAvailable:
            if (_showRestoreForm) {
              return _PrivateKeyRestoreScaffold(
                userId: widget.userId,
                encryptionService: widget.encryptionService,
                onRestored: _reloadStatus,
                onCancel: _signOutToLogin,
              );
            }
            return _KeyGateMessageScaffold(
              title: '端末引き継ぎ',
              message: 'Phase2で実装予定の端末引き継ぎをしますか？',
              actionLabel: 'OK',
              secondaryActionLabel: 'キャンセル',
              onAction: () async => setState(() => _showRestoreForm = true),
              onSecondaryAction: _signOutToLogin,
            );
          case SchedulePrivateKeySetupStatus.backupMissing:
            return _KeyGateMessageScaffold(
              title: '端末引き継ぎが必要です',
              message:
                  'この端末では暗号化された予定を表示できません。元の端末で引き継ぎ設定を行ってから、もう一度ログインしてください。',
              actionLabel: 'ログイン画面へ',
              onAction: _signOutToLogin,
            );
          case null:
            return _KeyGateMessageScaffold(
              title: '暗号化キーを確認できません',
              message: '通信状況を確認してから、もう一度ログインしてください。',
              actionLabel: 'ログイン画面へ',
              onAction: _signOutToLogin,
            );
        }
      },
    );
  }
}

class _PrivateKeyRestoreScaffold extends ConsumerStatefulWidget {
  const _PrivateKeyRestoreScaffold({
    required this.userId,
    required this.encryptionService,
    required this.onRestored,
    required this.onCancel,
  });

  final String userId;
  final ScheduleEncryptionService encryptionService;
  final VoidCallback onRestored;
  final Future<void> Function() onCancel;

  @override
  ConsumerState<_PrivateKeyRestoreScaffold> createState() =>
      _PrivateKeyRestoreScaffoldState();
}

class _PrivateKeyRestoreScaffoldState
    extends ConsumerState<_PrivateKeyRestoreScaffold> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('引き継ぎパスワードを入力してください')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.encryptionService.restorePrivateKeyFromBackup(
        uid: widget.userId,
        password: password,
      );
      widget.onRestored();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('引き継ぎパスワードが正しくありません')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('端末引き継ぎ')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            '暗号化された予定を表示するには、元の端末で設定した引き継ぎパスワードが必要です。',
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
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSubmitting ? null : _restore,
            child: _isSubmitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('復元する'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _isSubmitting ? null : widget.onCancel,
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }
}

class _KeyGateMessageScaffold extends StatelessWidget {
  const _KeyGateMessageScaffold({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function()? onAction;
  final String? secondaryActionLabel;
  final Future<void> Function()? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onAction == null ? null : () => onAction!(),
              child: Text(actionLabel),
            ),
            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => onSecondaryAction!(),
                child: Text(secondaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
