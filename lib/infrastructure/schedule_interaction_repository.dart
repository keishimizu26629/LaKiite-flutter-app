import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakiite/domain/entity/schedule_like.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';

class ScheduleInteractionRepository implements IScheduleInteractionRepository {
  final FirebaseFirestore _firestore;

  ScheduleInteractionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // いいね関連のメソッド
  @override
  Future<List<ScheduleLike>> getLikes(String scheduleId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('likes')
        .get();

    return snapshot.docs
        .map((doc) => ScheduleLike.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<void> addLike(String scheduleId, String userId) async {
    final likeDoc = _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('likes')
        .doc(userId);

    await likeDoc.set({
      'scheduleId': scheduleId,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeLike(String scheduleId, String userId) async {
    await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('likes')
        .doc(userId)
        .delete();
  }

  @override
  Stream<List<ScheduleLike>> watchLikes(String scheduleId) {
    return _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('likes')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScheduleLike.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }

  // コメント関連のメソッド
  @override
  Future<List<ScheduleComment>> getComments(String scheduleId) async {
    final snapshot = await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ScheduleComment.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  @override
  Future<void> addComment(
    String scheduleId,
    String userId,
    String content,
  ) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();

    await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('comments')
        .add({
      'scheduleId': scheduleId,
      'userId': userId,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
      'userDisplayName': userData?['displayName'],
      'userPhotoUrl': userData?['photoUrl'],
    });
  }

  @override
  Future<void> deleteComment(String scheduleId, String commentId) async {
    await _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  @override
  Stream<List<ScheduleComment>> watchComments(String scheduleId) {
    return _firestore
        .collection('schedules')
        .doc(scheduleId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScheduleComment.fromJson({...doc.data(), 'id': doc.id}))
            .toList());
  }
}