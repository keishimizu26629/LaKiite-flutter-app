class SchedulePlainDetails {
  const SchedulePlainDetails({
    required this.title,
    required this.description,
    this.location,
  });

  factory SchedulePlainDetails.fromJson(Map<String, dynamic> json) {
    return SchedulePlainDetails(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String?,
    );
  }

  final String title;
  final String description;
  final String? location;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'location': location,
      };
}

class ScheduleEncryptedPayload {
  const ScheduleEncryptedPayload({
    required this.cipherText,
    required this.nonce,
    required this.mac,
    required this.algorithm,
  });

  factory ScheduleEncryptedPayload.fromJson(Map<String, dynamic> json) {
    return ScheduleEncryptedPayload(
      cipherText: json['cipherText'] as String,
      nonce: json['nonce'] as String,
      mac: json['mac'] as String,
      algorithm: json['algorithm'] as String? ?? 'AES-GCM',
    );
  }

  final String cipherText;
  final String nonce;
  final String mac;
  final String algorithm;

  Map<String, dynamic> toJson() => {
        'cipherText': cipherText,
        'nonce': nonce,
        'mac': mac,
        'algorithm': algorithm,
      };
}

class ScheduleEncryptedKey {
  const ScheduleEncryptedKey({
    required this.encryptedScheduleKey,
    required this.nonce,
    required this.mac,
    required this.ephemeralPublicKey,
    required this.algorithm,
    required this.keyVersion,
  });

  factory ScheduleEncryptedKey.fromJson(Map<String, dynamic> json) {
    return ScheduleEncryptedKey(
      encryptedScheduleKey: json['encryptedScheduleKey'] as String,
      nonce: json['nonce'] as String,
      mac: json['mac'] as String,
      ephemeralPublicKey: json['ephemeralPublicKey'] as String,
      algorithm: json['algorithm'] as String? ?? 'X25519+AES-GCM',
      keyVersion: json['keyVersion'] as int? ?? 1,
    );
  }

  final String encryptedScheduleKey;
  final String nonce;
  final String mac;
  final String ephemeralPublicKey;
  final String algorithm;
  final int keyVersion;

  Map<String, dynamic> toJson() => {
        'encryptedScheduleKey': encryptedScheduleKey,
        'nonce': nonce,
        'mac': mac,
        'ephemeralPublicKey': ephemeralPublicKey,
        'algorithm': algorithm,
        'keyVersion': keyVersion,
      };
}

class ScheduleUserPublicKey {
  const ScheduleUserPublicKey({
    required this.uid,
    required this.publicKey,
    required this.keyVersion,
  });

  final String uid;
  final String publicKey;
  final int keyVersion;
}

class ScheduleEncryptionException implements Exception {
  const ScheduleEncryptionException(this.message);

  final String message;

  @override
  String toString() => 'ScheduleEncryptionException: $message';
}

class MissingLocalPrivateKeyException extends ScheduleEncryptionException {
  const MissingLocalPrivateKeyException(String uid)
      : super('Local private key is missing for user $uid');
}

class MissingRecipientPublicKeyException extends ScheduleEncryptionException {
  MissingRecipientPublicKeyException(List<String> userIds)
      : missingUserIds = userIds,
        super('Recipient public keys are missing: ${userIds.join(', ')}');

  final List<String> missingUserIds;
}
