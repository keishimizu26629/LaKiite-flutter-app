import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'schedule_cipher.dart';

class SchedulePrivateKeyStore {
  SchedulePrivateKeyStore({
    FlutterSecureStorage? secureStorage,
    ScheduleCipher? cipher,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _cipher = cipher ?? ScheduleCipher();

  final FlutterSecureStorage _secureStorage;
  final ScheduleCipher _cipher;

  Future<SimpleKeyPairData?> read({
    required String uid,
    required int keyVersion,
  }) async {
    final value = await _secureStorage.read(
      key: _key(uid: uid, keyVersion: keyVersion),
    );
    if (value == null) return null;
    return _cipher.privateKeyFromJson(value);
  }

  Future<void> write({
    required String uid,
    required int keyVersion,
    required SimpleKeyPairData keyPair,
  }) {
    return _secureStorage.write(
      key: _key(uid: uid, keyVersion: keyVersion),
      value: _cipher.privateKeyToJson(keyPair),
    );
  }

  Future<void> delete({
    required String uid,
    required int keyVersion,
  }) {
    return _secureStorage.delete(key: _key(uid: uid, keyVersion: keyVersion));
  }

  String _key({
    required String uid,
    required int keyVersion,
  }) {
    return 'lakiite.encryption.privateKey.$uid.$keyVersion';
  }
}
