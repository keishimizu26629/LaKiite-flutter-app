import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakiite/domain/entity/reaction.dart';
import 'package:lakiite/domain/repository/reaction_repository.dart';

class ReactionRepositoryImpl implements ReactionRepository {
  final FirebaseFirestore _firestore;

  ReactionRepositoryImpl(this._firestore);

  @override
  Future<List<Reaction>> getReactionsForSchedule(String scheduleId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('reactions')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Reaction.fromJson({
        'id': doc.id,
        'scheduleId': scheduleId,
        'userId': data['userId'] as String,
        'type': data['type'] as String,
        'userDisplayName': data['userDisplayName'] as String,
        'userPhotoUrl': data['userPhotoUrl'] as String?,
        'createdAt': data['createdAt'] as Timestamp,
      });
    }).toList();
  }

  @override
  Future<void> addReaction(
      String scheduleId, String userId, String type) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();

    await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('reactions')
        .doc(userId)
        .set({
      'userId': userId,
      'type': type,
      'userDisplayName': userData?['displayName'] as String,
      'userPhotoUrl': userData?['iconUrl'] as String?,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeReaction(String scheduleId, String userId) async {
    await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('reactions')
        .doc(userId)
        .delete();
  }
}
