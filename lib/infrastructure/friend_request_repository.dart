import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../domain/entity/friend_request.dart';
import '../domain/interfaces/i_friend_request_repository.dart';

class FriendRequestRepository implements IFriendRequestRepository {
  final FirebaseFirestore _firestore;

  FriendRequestRepository() : _firestore = FirebaseFirestore.instance;

  @override
  Future<void> createFriendRequest(FriendRequest request) async {
    debugPrint('Creating friend request: ${request.toFirestore()}');
    try {
      final docRef = _firestore.collection('friendRequests').doc();
      await docRef.set(request.toFirestore());
      debugPrint('Friend request created successfully with ID: ${docRef.id}');
    } catch (e) {
      debugPrint('Error creating friend request: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateFriendRequest(FriendRequest request) async {
    debugPrint('Updating friend request: ${request.id}');
    try {
      await _firestore
          .collection('friendRequests')
          .doc(request.id)
          .update(request.toFirestore());
      debugPrint('Friend request updated successfully: ${request.id}');
    } catch (e) {
      debugPrint('Error updating friend request: $e');
      rethrow;
    }
  }

  @override
  Future<FriendRequest?> getFriendRequest(String requestId) async {
    debugPrint('Getting friend request: $requestId');
    try {
      final doc = await _firestore.collection('friendRequests').doc(requestId).get();
      if (!doc.exists) {
        debugPrint('Friend request not found: $requestId');
        return null;
      }
      final data = doc.data()!;
      data['id'] = doc.id;
      debugPrint('Friend request retrieved successfully: $requestId');
      return FriendRequest.fromJson(data);
    } catch (e) {
      debugPrint('Error getting friend request: $e');
      rethrow;
    }
  }

  @override
  Stream<List<FriendRequest>> watchReceivedRequests(String userId) {
    debugPrint('Watching received requests for user: $userId');
    final query = _firestore
        .collection('friendRequests')
        .where('receiveUserId', isEqualTo: userId)
        .where('status', isEqualTo: FriendRequestStatus.pending.name)
        .orderBy('createdAt', descending: true);

    debugPrint('Query parameters: receiveUserId=$userId, status=${FriendRequestStatus.pending.name}, orderBy=createdAt desc');

    return query.snapshots().distinct().map((snapshot) {
      final requests = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return FriendRequest.fromJson(data);
      }).toList();
      debugPrint('Received ${requests.length} friend requests');
      return requests;
    });
  }

  @override
  Stream<List<FriendRequest>> watchSentRequests(String userId) {
    debugPrint('Watching sent requests for user: $userId');
    return _firestore
        .collection('friendRequests')
        .where('sendUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .distinct()
        .map((snapshot) {
          final requests = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return FriendRequest.fromJson(data);
          }).toList();
          debugPrint('Received ${requests.length} sent requests');
          return requests;
        });
  }

  @override
  Future<bool> hasPendingRequest(String fromUserId, String toUserId) async {
    debugPrint('Checking pending request from $fromUserId to $toUserId');
    try {
      final snapshot = await _firestore
          .collection('friendRequests')
          .where('sendUserId', isEqualTo: fromUserId)
          .where('receiveUserId', isEqualTo: toUserId)
          .where('status', isEqualTo: FriendRequestStatus.pending.name)
          .get();
      final hasPending = snapshot.docs.isNotEmpty;
      debugPrint('Pending request check result: $hasPending');
      return hasPending;
    } catch (e) {
      debugPrint('Error checking pending request: $e');
      rethrow;
    }
  }

  @override
  Future<void> acceptFriendRequest(String requestId) async {
    debugPrint('Accepting friend request: $requestId');
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': FriendRequestStatus.accepted.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Friend request accepted successfully: $requestId');
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
      rethrow;
    }
  }

  @override
  Future<void> rejectFriendRequest(String requestId) async {
    debugPrint('Rejecting friend request: $requestId');
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': FriendRequestStatus.rejected.name,
        'rejectionCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Friend request rejected successfully: $requestId');
    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String requestId) async {
    debugPrint('Marking friend request as read: $requestId');
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Friend request marked as read successfully: $requestId');
    } catch (e) {
      debugPrint('Error marking friend request as read: $e');
      rethrow;
    }
  }
}
