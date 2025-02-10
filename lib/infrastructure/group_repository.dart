import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entity/group.dart';
import '../domain/interfaces/i_group_repository.dart';

class GroupRepository implements IGroupRepository {
  final FirebaseFirestore _firestore;

  GroupRepository() : _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _toFirestore(Group group) {
    return {
      ...group.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  Group _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final createdAt = data['createdAt'] as Timestamp?;
    return Group(
      id: doc.id,
      groupName: data['groupName'] as String,
      ownerId: data['ownerId'] as String,
      memberIds: List<String>.from(data['memberIds'] as List),
      createdAt: createdAt?.toDate() ?? DateTime.now(),
    );
  }

  @override
  Future<List<Group>> getGroups() async {
    final snapshot = await _firestore.collection('groups').get();
    return snapshot.docs.map(_fromFirestore).toList();
  }

  @override
  Future<Group> createGroup({
    required String groupName,
    required List<String> memberIds,
    required String ownerId,
  }) async {
    final group = Group(
      id: '',  // 一時的な空のID
      groupName: groupName,
      memberIds: memberIds,
      ownerId: ownerId,
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore.collection('groups').add({
      'groupName': group.groupName,
      'memberIds': group.memberIds,
      'ownerId': group.ownerId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final doc = await docRef.get();
    return _fromFirestore(doc);
  }

  @override
  Future<void> updateGroup(Group group) async {
    await _firestore
        .collection('groups')
        .doc(group.id)
        .update(_toFirestore(group));
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _firestore.collection('groups').doc(groupId).delete();
  }

  @override
  Future<void> addMember(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }

  @override
  Stream<List<Group>> watchUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromFirestore).toList());
  }
}
