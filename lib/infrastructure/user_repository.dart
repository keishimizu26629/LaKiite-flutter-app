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

  @override
  Future<UserModel?> getUser(String id) async {
    final doc = await _firestore.collection('users').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return UserModel.fromJson(data);
  }

  @override
  Future<void> createUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toJson());
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toJson());
  }

  @override
  Future<void> deleteUser(String id) async {
    await _firestore.collection('users').doc(id).delete();
  }

  @override
  Future<String?> uploadUserIcon(String userId, Uint8List imageBytes) async {
    final ref = _storage.ref().child('user_icons/$userId.jpg');
    await ref.putData(imageBytes);
    return await ref.getDownloadURL();
  }

  @override
  Future<void> deleteUserIcon(String userId) async {
    final ref = _storage.ref().child('user_icons/$userId.jpg');
    await ref.delete();
  }

  @override
  Future<bool> isUserIdUnique(UserId userId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('userId', isEqualTo: userId.value)
        .get();
    return snapshot.docs.isEmpty;
  }

  @override
  Future<UserModel?> findByUserId(UserId userId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('userId', isEqualTo: userId.value)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    final data = doc.data();
    data['id'] = doc.id;
    return UserModel.fromJson(data);
  }

  @override
  Stream<UserModel?> watchUser(String id) {
    return _firestore.collection('users').doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return UserModel.fromJson(data);
    });
  }
}
