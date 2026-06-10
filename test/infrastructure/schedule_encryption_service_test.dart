import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule_encryption.dart';
import 'package:lakiite/infrastructure/encryption/schedule_encryption_service.dart';

void main() {
  group('ScheduleEncryptionService recipient planning', () {
    test('keeps ready recipients and reports recipients missing public keys',
        () {
      const ownerKey = ScheduleUserPublicKey(
        uid: 'owner',
        publicKey: 'owner-public-key',
        keyVersion: 1,
      );
      const readyKey = ScheduleUserPublicKey(
        uid: 'ready-user',
        publicKey: 'ready-public-key',
        keyVersion: 1,
      );

      final plan = ScheduleEncryptionService.planRecipientEncryption(
        viewerIds: const ['owner', 'ready-user', 'missing-user', 'owner'],
        publicKeys: const [ownerKey, readyKey],
      );

      expect(plan.readyUserIds, ['owner', 'ready-user']);
      expect(plan.missingUserIds, ['missing-user']);
      expect(plan.publicKeysByUserId, {
        'owner': ownerKey,
        'ready-user': readyKey,
      });
    });

    test('treats encrypted schedules without a user key as not displayable',
        () {
      expect(
        ScheduleEncryptionService.canDecryptScheduleData(
          const {
            'encrypted': true,
            'encryptedKeys': {
              'ready-user': {'encryptedScheduleKey': 'value'},
            },
          },
          currentUserId: 'ready-user',
        ),
        isTrue,
      );

      expect(
        ScheduleEncryptionService.canDecryptScheduleData(
          const {
            'encrypted': true,
            'encryptedKeys': {
              'ready-user': {'encryptedScheduleKey': 'value'},
            },
          },
          currentUserId: 'missing-user',
        ),
        isFalse,
      );
    });

    test('keeps unencrypted legacy schedules displayable', () {
      expect(
        ScheduleEncryptionService.canDecryptScheduleData(
          const {'encrypted': false},
          currentUserId: 'any-user',
        ),
        isTrue,
      );
    });
  });
}
