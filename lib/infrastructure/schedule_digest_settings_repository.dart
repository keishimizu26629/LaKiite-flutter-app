import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/entity/schedule_digest_settings.dart';
import '../domain/interfaces/i_schedule_digest_settings_repository.dart';

class ScheduleDigestSettingsRepository
    implements IScheduleDigestSettingsRepository {
  ScheduleDigestSettingsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String collectionPath = 'scheduleDigestSettings';

  @override
  Stream<ScheduleDigestSettings> watchCurrentUserSettings() {
    final userId = _currentUserId();
    return _firestore
        .collection(collectionPath)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) {
        return ScheduleDigestSettings.missingDocumentFallback(userId);
      }

      return ScheduleDigestSettings.fromFirestore(
        userId: userId,
        data: snapshot.data(),
      );
    });
  }

  @override
  Future<void> saveCurrentUserSettings(
    ScheduleDigestSettings settings,
  ) async {
    final userId = _currentUserId();
    await _firestore.collection(collectionPath).doc(userId).set(
          settings.toFirestore(),
          SetOptions(merge: true),
        );
  }

  String _currentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User not authenticated');
    }
    return user.uid;
  }
}
