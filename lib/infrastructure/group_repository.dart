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

  @override
  Future<List<Group>> getGroups() async {
    final snapshot = await _firestore.collection('groups').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Group.fromJson(data);
    }).toList();
  }

  @override
  Future<Group> createGroup({
    required String groupName,
    required List<String> memberIds,
    required String createdBy,
  }) async {
    final groupData = {
      'groupName': groupName,
      'memberIds': memberIds,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };

    final docRef = await _firestore.collection('groups').add(groupData);
    final doc = await docRef.get();
    final data = doc.data()!;
    data['id'] = doc.id;
    return Group.fromJson(data);
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

    await _firestore.collection('users').doc(userId).update({
      'groups': FieldValue.arrayUnion([groupId]),
    });
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    await _firestore.collection('users').doc(userId).update({
      'groups': FieldValue.arrayRemove([groupId]),
    });
  }

  @override
  Stream<List<Group>> watchUserGroups(String userId) {
    return _firestore
        .collection('groups')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Group.fromJson(data);
            }).toList());
  }
}
