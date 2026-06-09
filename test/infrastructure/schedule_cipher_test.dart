import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule_encryption.dart';
import 'package:lakiite/infrastructure/encryption/schedule_cipher.dart';

void main() {
  group('ScheduleCipher', () {
    test('encrypts details once and unwraps the schedule key for each viewer',
        () async {
      final cipher = ScheduleCipher();
      final ownerKeyPair = await cipher.newUserKeyPair();
      final viewerKeyPair = await cipher.newUserKeyPair();
      final scheduleKey = cipher.newScheduleKey();

      const details = SchedulePlainDetails(
        title: '打ち合わせ',
        description: '次回リリースの確認',
        location: '会議室A',
      );

      final encryptedPayload = await cipher.encryptDetails(
        details: details,
        scheduleKey: scheduleKey,
      );
      final ownerEncryptedKey = await cipher.encryptScheduleKey(
        scheduleKey: scheduleKey,
        recipientPublicKey: ownerKeyPair.publicKey,
        keyVersion: 1,
      );
      final viewerEncryptedKey = await cipher.encryptScheduleKey(
        scheduleKey: scheduleKey,
        recipientPublicKey: viewerKeyPair.publicKey,
        keyVersion: 1,
      );

      final ownerScheduleKey = await cipher.decryptScheduleKey(
        encryptedKey: ownerEncryptedKey,
        privateKey: ownerKeyPair,
      );
      final viewerScheduleKey = await cipher.decryptScheduleKey(
        encryptedKey: viewerEncryptedKey,
        privateKey: viewerKeyPair,
      );

      expect(
        await cipher.decryptDetails(
          payload: encryptedPayload,
          scheduleKey: ownerScheduleKey,
        ),
        isA<SchedulePlainDetails>()
            .having((value) => value.title, 'title', details.title)
            .having(
              (value) => value.description,
              'description',
              details.description,
            )
            .having((value) => value.location, 'location', details.location),
      );
      expect(
        await cipher.decryptDetails(
          payload: encryptedPayload,
          scheduleKey: viewerScheduleKey,
        ),
        isA<SchedulePlainDetails>()
            .having((value) => value.title, 'title', details.title),
      );
    });

    test('does not unwrap a schedule key with a different private key',
        () async {
      final cipher = ScheduleCipher();
      final viewerKeyPair = await cipher.newUserKeyPair();
      final otherKeyPair = await cipher.newUserKeyPair();
      final scheduleKey = cipher.newScheduleKey();

      final encryptedKey = await cipher.encryptScheduleKey(
        scheduleKey: scheduleKey,
        recipientPublicKey: viewerKeyPair.publicKey,
        keyVersion: 1,
      );

      expect(
        cipher.decryptScheduleKey(
          encryptedKey: encryptedKey,
          privateKey: otherKeyPair,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
