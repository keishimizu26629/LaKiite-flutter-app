import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entity/group.dart';
import '../domain/interfaces/i_group_repository.dart';

class GroupRepository implements IGroupRepository {
  final FirebaseFirestore _firestore;

  GroupRepository() : _firestore = FirebaseFirestore.instance;

  Map<String, dynamic> _toFirestore(Group group) {
    final data = group.toJson();
    if (data['createdAt'] != null) {
      data['createdAt'] = Timestamp.fromDate(group.createdAt);
    }
    return data;
  }

  Group _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['createdAt'] as Timestamp?;
    final modifiedData = Map<String, dynamic>.from(data);
    modifiedData['id'] = doc.id;
    modifiedData['createdAt'] = timestamp?.toDate().toIso8601String() ??
        DateTime.now().toIso8601String();
    return Group.fromJson(modifiedData);
  }

  @override
  Future<List<Group>> getGroups() async {
    final snapshot = await _firestore.collectionGroup('items').get();
    return snapshot.docs.map(_fromFirestore).toList();
  }

  @override
  Future<Group> createGroup({
    required String groupName,
    required List<String> memberIds,
    required String ownerId,
  }) async {
    final group = Group(
      id: '', // 一時的な空のID
      groupName: groupName,
      memberIds: memberIds,
      ownerId: ownerId,
      createdAt: DateTime.now(),
    );

    final docRef =
        await _firestore.collection('groups').add(_toFirestore(group));

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
