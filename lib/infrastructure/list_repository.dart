import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entity/list.dart';
import '../domain/interfaces/i_list_repository.dart';

class ListRepository implements IListRepository {
  ListRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Map<String, dynamic> _toFirestore(UserList list) {
    final data = list.toJson();
    if (data['createdAt'] != null) {
      data['createdAt'] = Timestamp.fromDate(list.createdAt);
    }
    return data;
  }

  UserList _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['createdAt'] as Timestamp?;
    final modifiedData = Map<String, dynamic>.from(data);
    modifiedData['id'] = doc.id;
    modifiedData['createdAt'] = timestamp?.toDate().toIso8601String() ??
        DateTime.now().toIso8601String();
    return UserList.fromJson(modifiedData);
  }

  @override
  Future<List<UserList>> getLists(String ownerId) async {
    final snapshot = await _firestore
        .collection('lists')
        .where('ownerId', isEqualTo: ownerId)
        .get();
    return snapshot.docs.map(_fromFirestore).toList();
  }

  @override
  Future<UserList> createList({
    required String listName,
    required List<String> memberIds,
    required String ownerId,
    String? iconUrl,
    String? description,
  }) async {
    final list = UserList(
      id: '', // 一時的な空のID
      listName: listName,
      memberIds: memberIds,
      ownerId: ownerId,
      createdAt: DateTime.now(),
      iconUrl: iconUrl,
      description: description,
    );

    final docRef = await _firestore.collection('lists').add(_toFirestore(list));

    final doc = await docRef.get();
    return _fromFirestore(doc);
  }

  @override
  Future<void> updateList(UserList list) async {
    await _firestore
        .collection('lists')
        .doc(list.id)
        .update(_toFirestore(list));
  }

  @override
  Future<void> deleteList(String listId) async {
    await _firestore.collection('lists').doc(listId).delete();
  }

  @override
  Future<void> addMember(String listId, String userId) async {
    await _firestore.collection('lists').doc(listId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  @override
  Future<void> removeMember(String listId, String userId) async {
    await _firestore.collection('lists').doc(listId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }

  @override
  Stream<List<UserList>> watchUserLists(String ownerId) {
    return _firestore
        .collection('lists')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromFirestore).toList());
  }

  @override
  Stream<UserList?> watchList(String listId) {
    return _firestore
        .collection('lists')
        .doc(listId)
        .snapshots()
        .map((doc) => doc.exists ? _fromFirestore(doc) : null);
  }

  @override
  Future<UserList?> getList(String listId) async {
    final doc = await _firestore.collection('lists').doc(listId).get();
    if (!doc.exists) return null;
    return _fromFirestore(doc);
  }
}
