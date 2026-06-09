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

  String _encode(List<int> bytes) => base64UrlEncode(bytes);

  List<int> _decode(String value) => base64Url.decode(value);
}
