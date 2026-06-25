import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/infrastructure/encryption/schedule_encryption_service.dart';
import 'package:lakiite/presentation/settings/schedule_key_backup_page.dart';

import '../../mock/base_mock.dart';

void main() {
  Widget buildTestTarget({bool hasBackup = false}) {
    final user = BaseMock.createTestUser();
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _StubAuthNotifier(AuthState.authenticated(user)),
        ),
        scheduleEncryptionServiceProvider.overrideWithValue(
          _StubScheduleEncryptionService(hasBackup: hasBackup),
        ),
      ],
      child: const MaterialApp(home: ScheduleKeyBackupPage()),
    );
  }

  Widget buildRefreshTestTarget(_StubScheduleEncryptionService service) {
    final user = BaseMock.createTestUser();
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          () => _StubAuthNotifier(AuthState.authenticated(user)),
        ),
        scheduleEncryptionServiceProvider.overrideWithValue(service),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) {
            final backupStatus = ref.watch(
              schedulePrivateKeyBackupExistsProvider(user.id),
            );
            return Scaffold(
              body: Column(
                children: [
                  Text('parent: ${backupStatus.valueOrNull == true}'),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ScheduleKeyBackupPage(),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('引き継ぎパスワードと確認用パスワードの表示切替は独立している', (tester) async {
    await tester.pumpWidget(buildTestTarget());

    expect(tester.widget<TextField>(find.byType(TextField).at(0)).obscureText,
        isTrue);
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isTrue);

    await tester.tap(find.byTooltip('引き継ぎパスワードを表示'));
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField).at(0)).obscureText,
        isFalse);
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isTrue);

    await tester.tap(find.byTooltip('確認用パスワードを表示'));
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField).at(0)).obscureText,
        isFalse);
    expect(tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
        isFalse);
  });

  testWidgets('既存の引き継ぎパスワードは保存時に上書きされることを表示する', (tester) async {
    await tester.pumpWidget(buildTestTarget(hasBackup: true));
    await tester.pump();

    expect(find.text('状態: 設定済み'), findsOneWidget);
    expect(find.text('新しい引き継ぎパスワード'), findsOneWidget);
    expect(find.text('引き継ぎパスワードを更新'), findsOneWidget);
    expect(find.textContaining('新しいパスワードで保存'), findsOneWidget);
  });

  testWidgets('引き継ぎパスワードが未設定の場合は未設定として表示する', (tester) async {
    await tester.pumpWidget(buildTestTarget());
    await tester.pump();

    expect(find.text('状態: 未設定'), findsOneWidget);
    expect(find.text('引き継ぎパスワード'), findsOneWidget);
    expect(find.text('保存'), findsOneWidget);
  });

  testWidgets('保存後に引き継ぎ設定状態を再取得する', (tester) async {
    final service = _StubScheduleEncryptionService(hasBackup: false);
    await tester.pumpWidget(buildRefreshTestTarget(service));
    await tester.pump();

    expect(find.text('parent: false'), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'new-password');
    await tester.enterText(find.byType(TextField).at(1), 'new-password');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('parent: true'), findsOneWidget);
  });
}

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._state);

  final AuthState _state;

  @override
  FutureOr<AuthState> build() => _state;
}

class _StubScheduleEncryptionService extends ScheduleEncryptionService {
  _StubScheduleEncryptionService({required this.hasBackup});

  bool hasBackup;

  @override
  Future<bool> hasPrivateKeyBackup(String uid) async {
    return hasBackup;
  }

  @override
  Future<void> createPrivateKeyBackup({
    required String uid,
    required String password,
  }) async {
    hasBackup = true;
  }
}
