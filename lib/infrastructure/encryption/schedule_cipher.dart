import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../domain/entity/schedule_encryption.dart';

class ScheduleCipher {
  ScheduleCipher({
    AesGcm? aesGcm,
    X25519? keyExchange,
  })  : _aesGcm = aesGcm ?? AesGcm.with256bits(),
        _keyExchange = keyExchange ?? X25519();

  static const payloadAlgorithm = 'AES-GCM';
  static const encryptedKeyAlgorithm = 'X25519+AES-GCM';
  static const privateKeyBackupKdf = 'PBKDF2-HMAC-SHA256';
  static const privateKeyBackupIterations = 210000;

  final AesGcm _aesGcm;
  final X25519 _keyExchange;

  Future<SimpleKeyPairData> newUserKeyPair() async {
    final keyPair = await _keyExchange.newKeyPair();
    final keyPairData = await keyPair.extract();
    final publicKey = await keyPair.extractPublicKey();
    return SimpleKeyPairData(
      keyPairData.bytes,
      publicKey: publicKey,
      type: KeyPairType.x25519,
    );
  }

  SecretKeyData newScheduleKey() => SecretKeyData.random(length: 32);

  Future<ScheduleEncryptedPayload> encryptDetails({
    required SchedulePlainDetails details,
    required SecretKey scheduleKey,
  }) async {
    final clearText = utf8.encode(jsonEncode(details.toJson()));
    final secretBox = await _aesGcm.encrypt(clearText, secretKey: scheduleKey);
    return ScheduleEncryptedPayload(
      cipherText: _encode(secretBox.cipherText),
      nonce: _encode(secretBox.nonce),
      mac: _encode(secretBox.mac.bytes),
      algorithm: payloadAlgorithm,
    );
  }

  Future<SchedulePlainDetails> decryptDetails({
    required ScheduleEncryptedPayload payload,
    required SecretKey scheduleKey,
  }) async {
    final clearText = await _aesGcm.decrypt(
      SecretBox(
        _decode(payload.cipherText),
        nonce: _decode(payload.nonce),
        mac: Mac(_decode(payload.mac)),
      ),
      secretKey: scheduleKey,
    );
    final json = jsonDecode(utf8.decode(clearText)) as Map<String, dynamic>;
    return SchedulePlainDetails.fromJson(json);
  }

  Future<ScheduleEncryptedPayload> encryptText({
    required String text,
    required SecretKey scheduleKey,
  }) async {
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(text),
      secretKey: scheduleKey,
    );
    return ScheduleEncryptedPayload(
      cipherText: _encode(secretBox.cipherText),
      nonce: _encode(secretBox.nonce),
      mac: _encode(secretBox.mac.bytes),
      algorithm: payloadAlgorithm,
    );
  }

  Future<String> decryptText({
    required ScheduleEncryptedPayload payload,
    required SecretKey scheduleKey,
  }) async {
    final clearText = await _aesGcm.decrypt(
      SecretBox(
        _decode(payload.cipherText),
        nonce: _decode(payload.nonce),
        mac: Mac(_decode(payload.mac)),
      ),
      secretKey: scheduleKey,
    );
    return utf8.decode(clearText);
  }

  Future<SchedulePrivateKeyBackup> encryptPrivateKeyBackup({
    required SimpleKeyPairData keyPair,
    required String password,
    required int keyVersion,
  }) async {
    final salt = SecretKeyData.random(length: 16).bytes;
    final backupKey = await _derivePrivateKeyBackupKey(
      password: password,
      salt: salt,
      iterations: privateKeyBackupIterations,
    );
    final secretBox = await _aesGcm.encrypt(
      utf8.encode(privateKeyToJson(keyPair)),
      secretKey: backupKey,
    );
    return SchedulePrivateKeyBackup(
      cipherText: _encode(secretBox.cipherText),
      nonce: _encode(secretBox.nonce),
      mac: _encode(secretBox.mac.bytes),
      algorithm: payloadAlgorithm,
      kdf: privateKeyBackupKdf,
      kdfIterations: privateKeyBackupIterations,
      salt: _encode(salt),
      keyVersion: keyVersion,
      version: 1,
    );
  }

  Future<SimpleKeyPairData> decryptPrivateKeyBackup({
    required SchedulePrivateKeyBackup backup,
    required String password,
  }) async {
    final backupKey = await _derivePrivateKeyBackupKey(
      password: password,
      salt: _decode(backup.salt),
      iterations: backup.kdfIterations,
    );
    final clearText = await _aesGcm.decrypt(
      SecretBox(
        _decode(backup.cipherText),
        nonce: _decode(backup.nonce),
        mac: Mac(_decode(backup.mac)),
      ),
      secretKey: backupKey,
    );
    return privateKeyFromJson(utf8.decode(clearText));
  }

  Future<ScheduleEncryptedKey> encryptScheduleKey({
    required SecretKeyData scheduleKey,
    required SimplePublicKey recipientPublicKey,
    required int keyVersion,
  }) async {
    final ephemeralKeyPair = await _keyExchange.newKeyPair();
    final sharedSecret = await _keyExchange.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: recipientPublicKey,
    );
    final scheduleKeyBytes = await scheduleKey.extractBytes();
    final secretBox = await _aesGcm.encrypt(
      scheduleKeyBytes,
      secretKey: sharedSecret,
    );
    final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();

    return ScheduleEncryptedKey(
      encryptedScheduleKey: _encode(secretBox.cipherText),
      nonce: _encode(secretBox.nonce),
      mac: _encode(secretBox.mac.bytes),
      ephemeralPublicKey: _encode(ephemeralPublicKey.bytes),
      algorithm: encryptedKeyAlgorithm,
      keyVersion: keyVersion,
    );
  }

  Future<SecretKeyData> decryptScheduleKey({
    required ScheduleEncryptedKey encryptedKey,
    required SimpleKeyPairData privateKey,
  }) async {
    final sharedSecret = await _keyExchange.sharedSecretKey(
      keyPair: privateKey,
      remotePublicKey: SimplePublicKey(
        _decode(encryptedKey.ephemeralPublicKey),
        type: KeyPairType.x25519,
      ),
    );
    final scheduleKeyBytes = await _aesGcm.decrypt(
      SecretBox(
        _decode(encryptedKey.encryptedScheduleKey),
        nonce: _decode(encryptedKey.nonce),
        mac: Mac(_decode(encryptedKey.mac)),
      ),
      secretKey: sharedSecret,
    );
    return SecretKeyData(scheduleKeyBytes);
  }

  SimplePublicKey publicKeyFromBase64(String value) {
    return SimplePublicKey(_decode(value), type: KeyPairType.x25519);
  }

  String publicKeyToBase64(SimplePublicKey publicKey) =>
      _encode(publicKey.bytes);

  bool publicKeyMatchesPrivateKey({
    required SimpleKeyPairData privateKey,
    required String publicKey,
  }) {
    return publicKeyToBase64(privateKey.publicKey) == publicKey;
  }

  String privateKeyToJson(SimpleKeyPairData keyPair) {
    return jsonEncode({
      'privateKey': _encode(keyPair.bytes),
      'publicKey': _encode(keyPair.publicKey.bytes),
      'type': 'x25519',
    });
  }

  SimpleKeyPairData privateKeyFromJson(String value) {
    final json = jsonDecode(value) as Map<String, dynamic>;
    return SimpleKeyPairData(
      _decode(json['privateKey'] as String),
      publicKey: SimplePublicKey(
        _decode(json['publicKey'] as String),
        type: KeyPairType.x25519,
      ),
      type: KeyPairType.x25519,
    );
  }

  Future<SecretKey> _derivePrivateKeyBackupKey({
    required String password,
    required List<int> salt,
    required int iterations,
  }) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  String _encode(List<int> bytes) => base64UrlEncode(bytes);

  List<int> _decode(String value) => base64Url.decode(value);
}
