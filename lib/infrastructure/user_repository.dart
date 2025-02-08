import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../domain/entity/user.dart';
import '../domain/interfaces/i_user_repository.dart';
import '../domain/value/user_id.dart';

class UserRepository implements IUserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  UserRepository()
      : _firestore = FirebaseFirestore.instance,
        _storage = FirebaseStorage.instance;

  Map<String, dynamic> _toFirestore(UserModel user) {
    return {
      'id': user.id,
      'name': user.name,
      'displayName': user.displayName,
      'searchId': user.searchId.toString(),
      'friends': user.friends,
      'iconUrl': user.iconUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel _fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] as String,
      displayName: data['displayName'] as String,
      searchId: UserId(data['searchId'] as String),
      friends: List<String>.from(data['friends'] as List),
      iconUrl: data['iconUrl'] as String?,
    );
  }

  @override
  Future<UserModel?> getUser(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (!doc.exists) return null;
    return _fromFirestore(doc);
  }

  @override
  Future<void> createUser(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.id)
        .set(_toFirestore(user));
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.id)
        .update(_toFirestore(user));
  }

  @override
  Future<void> deleteUser(String id) async {
    final user = await getUser(id);
    if (user?.iconUrl != null) {
      await deleteUserIcon(id);
    }
    await _firestore.collection('users').doc(id).delete();
  }

  @override
  Future<String?> uploadUserIcon(String userId, Uint8List imageBytes) async {
    try {
      final ref = _storage.ref().child('user_icons/$userId.jpg');
      await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final iconUrl = await ref.getDownloadURL();

      await _firestore.collection('users').doc(userId).update({
        'iconUrl': iconUrl,
      });

      return iconUrl;
    } catch (e) {
      print('Error uploading user icon: $e');
      return null;
    }
  }

  @override
  Future<void> deleteUserIcon(String userId) async {
    try {
      final ref = _storage.ref().child('user_icons/$userId.jpg');
      await ref.delete();

      await _firestore.collection('users').doc(userId).update({
        'iconUrl': null,
      });
    } catch (e) {
      print('Error deleting user icon: $e');
    }
  }

  @override
  Future<bool> isUserIdUnique(UserId userId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('searchId', isEqualTo: userId.toString())
        .get();
    return snapshot.docs.isEmpty;
  }

  @override
  Future<UserModel?> findByUserId(UserId userId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('searchId', isEqualTo: userId.toString())
        .get();

    if (snapshot.docs.isEmpty) return null;
    return _fromFirestore(snapshot.docs.first);
  }
}
