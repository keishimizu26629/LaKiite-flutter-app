import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entity/friend_request.dart';
import '../domain/interfaces/i_friend_request_repository.dart';

class FriendRequestRepository implements IFriendRequestRepository {
  final FirebaseFirestore _firestore;

  FriendRequestRepository() : _firestore = FirebaseFirestore.instance;

  @override
  Future<void> createFriendRequest(FriendRequest request) async {
    final docRef = _firestore.collection('friendRequests').doc();
    await docRef.set(request.toFirestore());
  }

  @override
  Future<void> updateFriendRequest(FriendRequest request) async {
    await _firestore
        .collection('friendRequests')
        .doc(request.id)
        .update(request.toFirestore());
  }

  @override
  Future<FriendRequest?> getFriendRequest(String requestId) async {
    final doc = await _firestore.collection('friendRequests').doc(requestId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return FriendRequest.fromJson(data);
  }

  @override
  Stream<List<FriendRequest>> watchReceivedRequests(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('participants', arrayContains: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return FriendRequest.fromJson(data);
            }).toList());
  }

  @override
  Stream<List<FriendRequest>> watchSentRequests(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('participants', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return FriendRequest.fromJson(data);
            }).toList());
  }

  @override
  Future<bool> hasPendingRequest(String fromUserId, String toUserId) async {
    final snapshot = await _firestore
        .collection('friendRequests')
        .where('participants', arrayContainsAny: [fromUserId, toUserId])
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    await _firestore.collection('friendRequests').doc(requestId).update({
      'status': FriendRequestStatus.accepted.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> rejectFriendRequest(String requestId) async {
    await _firestore.collection('friendRequests').doc(requestId).update({
      'status': FriendRequestStatus.rejected.name,
      'rejectionCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> markAsRead(String requestId) async {
    await _firestore.collection('friendRequests').doc(requestId).update({
      'isRead': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
