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

  Map<String, dynamic> _toFirestorePublic(PublicUserModel publicProfile) {
    final json = publicProfile.toJson();
    // UserIdを文字列に変換
    json['searchId'] = json['searchId'].toString();
    return json;
  }

  Map<String, dynamic> _toFirestorePrivate(PrivateUserModel privateProfile) {
    final json = privateProfile.toJson();
    // listsフィールドがnullの場合は空のリストを設定
    json['lists'] = json['lists'] ?? [];
    return json;
  }

  @override
  Future<UserModel?> getUser(String id) async {
    final userDoc = await _firestore.collection('users').doc(id).get();
    if (!userDoc.exists) return null;

    final privateDoc = await _firestore
        .collection('users')
        .doc(id)
        .collection('private')
        .doc('profile')
        .get();
    if (!privateDoc.exists) return null;

    final publicData = userDoc.data()!;
    publicData['id'] = userDoc.id;

    final privateData = privateDoc.data()!;
    privateData['lists'] = privateData['lists'] ?? [];

    return UserModel(
      publicProfile: PublicUserModel.fromJson(publicData),
      privateProfile: PrivateUserModel.fromJson(privateData),
    );
  }

  // 友達の公開情報のみを取得するメソッド
  Future<PublicUserModel?> getFriendPublicProfile(String id) async {
    final userDoc = await _firestore.collection('users').doc(id).get();
    if (!userDoc.exists) return null;
    final data = userDoc.data()!;
    data['id'] = userDoc.id;
    return PublicUserModel.fromJson(data);
  }

  @override
  Future<void> createUser(UserModel user) async {
    try {
      // searchIdの一意性をチェック
      final isUnique = await isUserIdUnique(user.searchId);
      if (!isUnique) {
        throw Exception('このsearchIdは既に使用されています');
      }

      // ドキュメントの参照を取得
      final userRef = _firestore.collection('users').doc(user.id);
      final privateRef = userRef.collection('private').doc('profile');

      // トランザクションでユーザーデータを作成
      await _firestore.runTransaction((transaction) async {
        // ドキュメントの存在チェック
        final docSnapshot = await transaction.get(userRef);
        if (docSnapshot.exists) {
          throw Exception('ユーザーデータが既に存在します');
        }

        // 公開情報を親ドキュメントに保存
        transaction.set(userRef, _toFirestorePublic(user.publicProfile));

        // 非公開情報をprivateサブコレクションに保存
        transaction.set(privateRef, _toFirestorePrivate(user.privateProfile));
      });
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    final userRef = _firestore.collection('users').doc(user.id);
    final privateRef = userRef.collection('private').doc('profile');

    await _firestore.runTransaction((transaction) async {
      // 公開情報を更新
      transaction.update(userRef, _toFirestorePublic(user.publicProfile));

      // 非公開情報を更新
      transaction.update(privateRef, _toFirestorePrivate(user.privateProfile));
    });
  }

  @override
  Future<void> deleteUser(String id) async {
    final userRef = _firestore.collection('users').doc(id);
    final privateRef = userRef.collection('private').doc('profile');

    await _firestore.runTransaction((transaction) async {
      // privateプロフィールを削除
      transaction.delete(privateRef);
      // ユーザードキュメントを削除
      transaction.delete(userRef);
    });
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
        .where('searchId', isEqualTo: userId.value)
        .get();
    return snapshot.docs.isEmpty;
  }

  @override
  Future<SearchUserModel?> findByUserId(UserId userId) async {
    return findBySearchId(userId.value);
  }

  @override
  Future<SearchUserModel?> findBySearchId(String searchId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('searchId', isEqualTo: searchId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('User not found with searchId: $searchId');
        return null;
      }

      final userDoc = snapshot.docs.first;
      final data = userDoc.data();

      print('Found user document:');
      print('Document ID: ${userDoc.id}');
      print('Data: $data');

      return SearchUserModel.fromFirestore(userDoc.id, data);
    } catch (e) {
      print('Error searching user: $e');
      return null;
    }
  }

  @override
  Stream<PublicUserModel?> watchPublicProfile(String id) {
    return _firestore
        .collection('users')
        .doc(id)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          final data = doc.data()!;
          data['id'] = doc.id;
          return PublicUserModel.fromJson(data);
        });
  }

  @override
  Stream<PrivateUserModel?> watchPrivateProfile(String id) {
    return _firestore
        .collection('users')
        .doc(id)
        .collection('private')
        .doc('profile')
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          final data = doc.data()!;
          data['lists'] = data['lists'] ?? [];
          return PrivateUserModel.fromJson(data);
        });
  }

  @override
  Stream<UserModel?> watchUser(String id) {
    return _firestore
        .collection('users')
        .doc(id)
        .snapshots()
        .asyncMap((publicDoc) async {
      if (!publicDoc.exists) return null;

      final privateDoc = await _firestore
          .collection('users')
          .doc(id)
          .collection('private')
          .doc('profile')
          .get();

      if (!privateDoc.exists) return null;

      final publicData = publicDoc.data()!;
      publicData['id'] = publicDoc.id;

      final privateData = privateDoc.data()!;
      privateData['lists'] = privateData['lists'] ?? [];

      return UserModel(
        publicProfile: PublicUserModel.fromJson(publicData),
        privateProfile: PrivateUserModel.fromJson(privateData),
      );
    });
  }

  @override
  Future<void> addToList(String userId, String memberId) async {
    final privateRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('private')
        .doc('profile');

    await privateRef.update({
      'lists': FieldValue.arrayUnion([memberId]),
    });
  }

  @override
  Future<void> removeFromList(String userId, String memberId) async {
    final privateRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('private')
        .doc('profile');

    await privateRef.update({
      'lists': FieldValue.arrayRemove([memberId]),
    });
  }

  // 複数のユーザーの公開情報を一度に取得
  Future<List<PublicUserModel>> getPublicProfiles(List<String> userIds) async {
    final futures = userIds.map((id) => _firestore
        .collection('users')
        .doc(id)
        .get()
        .then((doc) {
          if (!doc.exists) return null;
          final data = doc.data()!;
          data['id'] = doc.id;
          return PublicUserModel.fromJson(data);
        }));

    final results = await Future.wait(futures);
    return results.where((user) => user != null).cast<PublicUserModel>().toList();
  }
}
