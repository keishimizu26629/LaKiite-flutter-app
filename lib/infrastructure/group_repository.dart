import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tarakite/domain/entity/group.dart';
import 'package:tarakite/domain/interfaces/i_group_repository.dart';

class GroupRepository implements IGroupRepository {
  final FirebaseFirestore _firestore;

  GroupRepository(this._firestore);

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
    await _firestore.collection('groups').doc(group.id).update(group.toJson());
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

    // ユーザーのグループリストも更新
    await _firestore.collection('users').doc(userId).update({
      'groups': FieldValue.arrayUnion([groupId]),
    });
  }

  @override
  Future<void> removeMember(String groupId, String userId) async {
    await _firestore.collection('groups').doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    // ユーザーのグループリストからも削除
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
