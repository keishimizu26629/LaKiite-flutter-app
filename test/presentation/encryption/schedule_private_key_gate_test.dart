import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule_encryption.dart';
import 'package:lakiite/infrastructure/encryption/schedule_encryption_service.dart';
import 'package:lakiite/presentation/encryption/schedule_private_key_gate.dart';

void main() {
  testWidgets('復元した秘密キーが現在の公開キーと一致しない場合は専用メッセージを表示する', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: SchedulePrivateKeyGate(
            userId: 'user-1',
            encryptionService: _MismatchedRestoreScheduleEncryptionService(),
            child: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'testtest');
    await tester.tap(find.text('復元する'));
    await tester.pump();

    expect(
      find.text('保存されている引き継ぎキーが現在の暗号化キーと一致しません'),
      findsOneWidget,
    );
  });
}

class _MismatchedRestoreScheduleEncryptionService
    extends ScheduleEncryptionService {
  @override
  Future<SchedulePrivateKeySetupStatus> currentUserPrivateKeyStatus(
    String uid,
  ) async {
    return SchedulePrivateKeySetupStatus.restoreAvailable;
  }

  @override
  Future<void> restorePrivateKeyFromBackup({
    required String uid,
    required String password,
  }) async {
    throw const RestoredPrivateKeyMismatchException('user-1');
  }
}
