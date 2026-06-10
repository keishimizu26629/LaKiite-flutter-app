import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';

import '../../domain/entity/schedule.dart';
import '../../domain/entity/schedule_encryption.dart';
import '../mapper/schedule_mapper.dart';
import 'schedule_cipher.dart';
import 'schedule_private_key_store.dart';

class ScheduleEncryptionService {
  ScheduleEncryptionService({
    FirebaseFirestore? firestore,
    ScheduleCipher? cipher,
    SchedulePrivateKeyStore? privateKeyStore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cipher = cipher ?? ScheduleCipher(),
        _privateKeyStore = privateKeyStore ?? SchedulePrivateKeyStore();

  static const encryptionVersion = 1;
  static const currentKeyVersion = 1;

  final FirebaseFirestore _firestore;
  final ScheduleCipher _cipher;
  final SchedulePrivateKeyStore _privateKeyStore;

  Future<void> tryEnsureCurrentUserKey(String uid) async {
    try {
      await ensureCurrentUserKey(uid);
    } on MissingLocalPrivateKeyException {
      // 復元導線はログイン後のガードで扱う。読み込み自体は継続する。
    }
  }

  Future<SchedulePrivateKeySetupStatus> currentUserPrivateKeyStatus(
    String uid,
  ) async {
    final publicKeyDoc = await _publicKeyRef(uid).get();
    if (!publicKeyDoc.exists) {
      return SchedulePrivateKeySetupStatus.notStarted;
    }

    final data = publicKeyDoc.data() as Map<String, dynamic>;
    final keyVersion = data['keyVersion'] as int? ?? currentKeyVersion;
    final localKey = await _privateKeyStore.read(
      uid: uid,
      keyVersion: keyVersion,
    );
    if (localKey != null) {
      return SchedulePrivateKeySetupStatus.ready;
    }

    return _privateKeyBackupFromData(data) == null
        ? SchedulePrivateKeySetupStatus.backupMissing
        : SchedulePrivateKeySetupStatus.restoreAvailable;
  }

  Future<SimpleKeyPairData> ensureCurrentUserKey(String uid) async {
    final publicKeyRef = _publicKeyRef(uid);
    final publicKeyDoc = await publicKeyRef.get();

    if (publicKeyDoc.exists) {
      final data = publicKeyDoc.data() as Map<String, dynamic>;
      final keyVersion = data['keyVersion'] as int? ?? currentKeyVersion;
      final localKey = await _privateKeyStore.read(
        uid: uid,
        keyVersion: keyVersion,
      );
      if (localKey == null) {
        throw MissingLocalPrivateKeyException(uid);
      }
      return localKey;
    }

    final existingLocalKey = await _privateKeyStore.read(
      uid: uid,
      keyVersion: currentKeyVersion,
    );
    if (existingLocalKey != null) {
      await _savePublicKey(uid: uid, keyPair: existingLocalKey);
      return existingLocalKey;
    }

    final keyPair = await _cipher.newUserKeyPair();
    await _privateKeyStore.write(
      uid: uid,
      keyVersion: currentKeyVersion,
      keyPair: keyPair,
    );
    await _savePublicKey(uid: uid, keyPair: keyPair);
    return keyPair;
  }

  Future<void> createPrivateKeyBackup({
    required String uid,
    required String password,
  }) async {
    final keyPair = await ensureCurrentUserKey(uid);
    final backup = await _cipher.encryptPrivateKeyBackup(
      keyPair: keyPair,
      password: password,
      keyVersion: currentKeyVersion,
    );

    await _publicKeyRef(uid).set({
      'encryptedPrivateKeyBackup': backup.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> restorePrivateKeyFromBackup({
    required String uid,
    required String password,
  }) async {
    final publicKeyDoc = await _publicKeyRef(uid).get();
    if (!publicKeyDoc.exists) {
      throw const ScheduleEncryptionException(
        'Private key backup is missing',
      );
    }

    final data = publicKeyDoc.data() as Map<String, dynamic>;
    final backup = _privateKeyBackupFromData(data);
    if (backup == null) {
      throw const ScheduleEncryptionException(
        'Private key backup is missing',
      );
    }

    final keyPair = await _cipher.decryptPrivateKeyBackup(
      backup: backup,
      password: password,
    );
    final expectedPublicKey = data['publicKey'] as String?;
    if (expectedPublicKey != null &&
        expectedPublicKey != _cipher.publicKeyToBase64(keyPair.publicKey)) {
      throw const ScheduleEncryptionException(
        'Restored private key does not match the current public key',
      );
    }

    await _privateKeyStore.write(
      uid: uid,
      keyVersion: backup.keyVersion,
      keyPair: keyPair,
    );
  }

  Future<Map<String, dynamic>> toEncryptedFirestoreData({
    required Schedule schedule,
    required String currentUserId,
    DocumentSnapshot? existingDoc,
  }) async {
    final currentUserKey = await ensureCurrentUserKey(currentUserId);
    final scheduleKey = await _resolveScheduleKey(
      currentUserId: currentUserId,
      currentUserKey: currentUserKey,
      existingDoc: existingDoc,
    );

    final details = SchedulePlainDetails(
      title: schedule.title,
      description: schedule.description,
      location: schedule.location,
    );
    final payload = await _cipher.encryptDetails(
      details: details,
      scheduleKey: scheduleKey,
    );
    final encryptedKeys = await _encryptScheduleKeyForViewers(
      scheduleKey: scheduleKey,
      viewerIds: schedule.visibleTo,
    );

    final data = ScheduleMapper.toFirestore(schedule);
    data
      ..remove('title')
      ..remove('description')
      ..remove('location')
      ..['encrypted'] = true
      ..['encryptionVersion'] = encryptionVersion
      ..['encryptedPayload'] = payload.toJson()
      ..['encryptedKeys'] = encryptedKeys.map(
        (uid, encryptedKey) => MapEntry(uid, encryptedKey.toJson()),
      );
    return data;
  }

  Future<SchedulePlainDetails?> decryptDetailsForCurrentUser({
    required DocumentSnapshot doc,
    required String currentUserId,
  }) async {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null || data['encrypted'] != true) return null;

    final scheduleKey = await _decryptScheduleKeyFromData(
      data: data,
      currentUserId: currentUserId,
    );
    final payload = ScheduleEncryptedPayload.fromJson(
      Map<String, dynamic>.from(data['encryptedPayload'] as Map),
    );
    return _cipher.decryptDetails(
      payload: payload,
      scheduleKey: scheduleKey,
    );
  }

  Future<ScheduleEncryptedKey?> encryptedScheduleKeyForAdditionalViewer({
    required DocumentSnapshot doc,
    required String currentUserId,
    required String viewerId,
  }) async {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null || data['encrypted'] != true) return null;

    final scheduleKey = await _decryptScheduleKeyFromData(
      data: data,
      currentUserId: currentUserId,
    );
    final publicKey = (await _fetchPublicKeys({viewerId})).single;
    return _cipher.encryptScheduleKey(
      scheduleKey: scheduleKey,
      recipientPublicKey: _cipher.publicKeyFromBase64(publicKey.publicKey),
      keyVersion: publicKey.keyVersion,
    );
  }

  Future<Map<String, dynamic>> toEncryptedCommentContentData({
    required DocumentSnapshot scheduleDoc,
    required String currentUserId,
    required String content,
  }) async {
    final scheduleKey = await scheduleKeyForCurrentUser(
      scheduleDoc: scheduleDoc,
      currentUserId: currentUserId,
    );
    if (scheduleKey == null) {
      return {'content': content};
    }

    final payload = await _cipher.encryptText(
      text: content,
      scheduleKey: scheduleKey,
    );
    return {
      'encrypted': true,
      'encryptedContent': payload.toJson(),
    };
  }

  Future<String> decryptCommentContentForCurrentUser({
    required DocumentSnapshot scheduleDoc,
    required String currentUserId,
    required Map<String, dynamic> commentData,
  }) async {
    if (commentData['encrypted'] != true) {
      return commentData['content'] as String? ?? '';
    }

    final scheduleKey = await scheduleKeyForCurrentUser(
      scheduleDoc: scheduleDoc,
      currentUserId: currentUserId,
    );
    if (scheduleKey == null) {
      throw const ScheduleEncryptionException(
        'Parent schedule is not encrypted',
      );
    }

    final payload = ScheduleEncryptedPayload.fromJson(
      Map<String, dynamic>.from(commentData['encryptedContent'] as Map),
    );
    return _cipher.decryptText(payload: payload, scheduleKey: scheduleKey);
  }

  Future<SecretKeyData?> scheduleKeyForCurrentUser({
    required DocumentSnapshot scheduleDoc,
    required String currentUserId,
  }) async {
    final data = scheduleDoc.data() as Map<String, dynamic>?;
    if (data == null || data['encrypted'] != true) return null;

    return _decryptScheduleKeyFromData(
      data: data,
      currentUserId: currentUserId,
    );
  }

  Future<void> _savePublicKey({
    required String uid,
    required SimpleKeyPairData keyPair,
  }) async {
    await _publicKeyRef(uid).set({
      'publicKey': _cipher.publicKeyToBase64(keyPair.publicKey),
      'keyVersion': currentKeyVersion,
      'algorithm': 'X25519',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<SecretKeyData> _resolveScheduleKey({
    required String currentUserId,
    required SimpleKeyPairData currentUserKey,
    required DocumentSnapshot? existingDoc,
  }) async {
    final existingData = existingDoc?.data() as Map<String, dynamic>?;
    if (existingData == null || existingData['encrypted'] != true) {
      return _cipher.newScheduleKey();
    }

    final encryptedKeys = existingData['encryptedKeys'] as Map?;
    final encryptedKeyJson = encryptedKeys?[currentUserId];
    if (encryptedKeyJson == null) {
      throw const ScheduleEncryptionException(
        'Encrypted schedule key for current user is missing',
      );
    }
    return _cipher.decryptScheduleKey(
      encryptedKey: ScheduleEncryptedKey.fromJson(
        Map<String, dynamic>.from(encryptedKeyJson as Map),
      ),
      privateKey: currentUserKey,
    );
  }

  Future<SecretKeyData> _decryptScheduleKeyFromData({
    required Map<String, dynamic> data,
    required String currentUserId,
  }) async {
    final encryptedKeys = data['encryptedKeys'] as Map?;
    final encryptedKeyJson = encryptedKeys?[currentUserId];
    if (encryptedKeyJson == null) {
      throw const ScheduleEncryptionException(
        'Encrypted schedule key for current user is missing',
      );
    }

    final encryptedKey = ScheduleEncryptedKey.fromJson(
      Map<String, dynamic>.from(encryptedKeyJson as Map),
    );
    final privateKey = await _privateKeyStore.read(
      uid: currentUserId,
      keyVersion: encryptedKey.keyVersion,
    );
    if (privateKey == null) {
      throw MissingLocalPrivateKeyException(currentUserId);
    }
    return _cipher.decryptScheduleKey(
      encryptedKey: encryptedKey,
      privateKey: privateKey,
    );
  }

  Future<Map<String, ScheduleEncryptedKey>> _encryptScheduleKeyForViewers({
    required SecretKeyData scheduleKey,
    required Iterable<String> viewerIds,
  }) async {
    final publicKeys = await _fetchPublicKeys(viewerIds.toSet());
    final entries = await Future.wait(publicKeys.map((publicKey) async {
      final encryptedKey = await _cipher.encryptScheduleKey(
        scheduleKey: scheduleKey,
        recipientPublicKey: _cipher.publicKeyFromBase64(publicKey.publicKey),
        keyVersion: publicKey.keyVersion,
      );
      return MapEntry(publicKey.uid, encryptedKey);
    }));
    return Map.fromEntries(entries);
  }

  Future<List<ScheduleUserPublicKey>> _fetchPublicKeys(
    Set<String> viewerIds,
  ) async {
    final results = await Future.wait(viewerIds.map((uid) async {
      final doc = await _publicKeyRef(uid).get();
      if (!doc.exists) return null;
      final data = doc.data() as Map<String, dynamic>;
      return ScheduleUserPublicKey(
        uid: uid,
        publicKey: data['publicKey'] as String,
        keyVersion: data['keyVersion'] as int? ?? currentKeyVersion,
      );
    }));
    final publicKeys = results.whereType<ScheduleUserPublicKey>().toList();
    final foundUserIds = publicKeys.map((key) => key.uid).toSet();
    final missingUserIds = viewerIds.difference(foundUserIds).toList();
    if (missingUserIds.isNotEmpty) {
      throw MissingRecipientPublicKeyException(missingUserIds);
    }
    return publicKeys;
  }

  DocumentReference _publicKeyRef(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('encryption')
        .doc('current');
  }

  SchedulePrivateKeyBackup? _privateKeyBackupFromData(
    Map<String, dynamic> data,
  ) {
    final backupJson = data['encryptedPrivateKeyBackup'];
    if (backupJson is! Map) return null;
    return SchedulePrivateKeyBackup.fromJson(
      Map<String, dynamic>.from(backupJson),
    );
  }
}
