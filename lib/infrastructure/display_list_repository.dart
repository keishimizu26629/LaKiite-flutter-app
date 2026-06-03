import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lakiite/domain/entity/display_list.dart';
import 'package:lakiite/domain/interfaces/i_display_list_repository.dart';

class DisplayListRepository implements IDisplayListRepository {
  DisplayListRepository() : _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String ownerId) {
    return _firestore
        .collection('users')
        .doc(ownerId)
        .collection('displayLists');
  }

  static DateTime parseDateTime(Object? value, {DateTime? fallback}) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
    }
    return fallback ?? DateTime.now();
  }

  Map<String, dynamic> _toFirestore(DisplayList displayList) {
    return {
      'name': displayList.name,
      'ownerId': displayList.ownerId,
      'colorKey': displayList.colorKey,
      'memberIds': displayList.memberIds,
      'createdAt': Timestamp.fromDate(displayList.createdAt),
      'updatedAt': Timestamp.fromDate(displayList.updatedAt),
    };
  }

  DisplayList _fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return DisplayList(
      id: doc.id,
      name: data['name'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? doc.reference.parent.parent!.id,
      colorKey: data['colorKey'] as String? ?? 'blue',
      memberIds: List<String>.from(data['memberIds'] as List? ?? []),
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
    );
  }

  @override
  Future<List<DisplayList>> getDisplayLists(String ownerId) async {
    final snapshot = await _collection(ownerId)
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs.map(_fromFirestore).toList();
  }

  @override
  Stream<List<DisplayList>> watchDisplayLists(String ownerId) {
    return _collection(ownerId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromFirestore).toList());
  }

  @override
  Future<DisplayList> createDisplayList({
    required String ownerId,
    required String name,
    required String colorKey,
    required List<String> memberIds,
  }) async {
    final now = DateTime.now();
    final displayList = DisplayList(
      id: '',
      name: name,
      ownerId: ownerId,
      colorKey: colorKey,
      memberIds: memberIds,
      createdAt: now,
      updatedAt: now,
    );
    final docRef = await _collection(ownerId).add(_toFirestore(displayList));
    final doc = await docRef.get();
    return _fromFirestore(doc);
  }

  @override
  Future<void> updateDisplayList(DisplayList displayList) async {
    await _collection(displayList.ownerId).doc(displayList.id).update(
          _toFirestore(displayList.copyWith(updatedAt: DateTime.now())),
        );
  }

  @override
  Future<void> deleteDisplayList({
    required String ownerId,
    required String displayListId,
  }) async {
    await _collection(ownerId).doc(displayListId).delete();
  }

  @override
  Future<void> addMember({
    required String ownerId,
    required String displayListId,
    required String userId,
  }) async {
    await _collection(ownerId).doc(displayListId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> removeMember({
    required String ownerId,
    required String displayListId,
    required String userId,
  }) async {
    await _collection(ownerId).doc(displayListId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
