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

class SchedulePrivateKeyBackup {
  const SchedulePrivateKeyBackup({
    required this.cipherText,
    required this.nonce,
    required this.mac,
    required this.algorithm,
    required this.kdf,
    required this.kdfIterations,
    required this.salt,
    required this.keyVersion,
    required this.version,
  });

  factory SchedulePrivateKeyBackup.fromJson(Map<String, dynamic> json) {
    return SchedulePrivateKeyBackup(
      cipherText: json['cipherText'] as String,
      nonce: json['nonce'] as String,
      mac: json['mac'] as String,
      algorithm: json['algorithm'] as String? ?? 'AES-GCM',
      kdf: json['kdf'] as String? ?? 'PBKDF2-HMAC-SHA256',
      kdfIterations: json['kdfIterations'] as int? ?? 210000,
      salt: json['salt'] as String,
      keyVersion: json['keyVersion'] as int? ?? 1,
      version: json['version'] as int? ?? 1,
    );
  }

  final String cipherText;
  final String nonce;
  final String mac;
  final String algorithm;
  final String kdf;
  final int kdfIterations;
  final String salt;
  final int keyVersion;
  final int version;

  Map<String, dynamic> toJson() => {
        'cipherText': cipherText,
        'nonce': nonce,
        'mac': mac,
        'algorithm': algorithm,
        'kdf': kdf,
        'kdfIterations': kdfIterations,
        'salt': salt,
        'keyVersion': keyVersion,
        'version': version,
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

class ScheduleMigrationPublicKey {
  const ScheduleMigrationPublicKey({
    required this.keyId,
    required this.publicKey,
    required this.keyVersion,
  });

  factory ScheduleMigrationPublicKey.fromJson(Map<String, dynamic> json) {
    return ScheduleMigrationPublicKey(
      keyId: json['keyId'] as String,
      publicKey: json['publicKey'] as String,
      keyVersion: json['keyVersion'] as int? ?? 1,
    );
  }

  final String keyId;
  final String publicKey;
  final int keyVersion;
}

class SchedulePendingEncryptedRecipient {
  const SchedulePendingEncryptedRecipient({
    required this.reason,
    required this.migrationKeyId,
    required this.sharedListIds,
  });

  factory SchedulePendingEncryptedRecipient.fromJson(
    Map<String, dynamic> json,
  ) {
    return SchedulePendingEncryptedRecipient(
      reason: json['reason'] as String? ?? 'missingPublicKey',
      migrationKeyId: json['migrationKeyId'] as String,
      sharedListIds: List<String>.from(json['sharedListIds'] as List? ?? []),
    );
  }

  final String reason;
  final String migrationKeyId;
  final List<String> sharedListIds;

  Map<String, dynamic> toJson() => {
        'reason': reason,
        'migrationKeyId': migrationKeyId,
        'sharedListIds': sharedListIds,
      };
}

class ScheduleRecipientEncryptionPlan {
  const ScheduleRecipientEncryptionPlan({
    required this.publicKeysByUserId,
    required this.readyUserIds,
    required this.missingUserIds,
  });

  final Map<String, ScheduleUserPublicKey> publicKeysByUserId;
  final List<String> readyUserIds;
  final List<String> missingUserIds;
}

enum SchedulePrivateKeySetupStatus {
  ready,
  notStarted,
  restoreAvailable,
  backupMissing,
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
