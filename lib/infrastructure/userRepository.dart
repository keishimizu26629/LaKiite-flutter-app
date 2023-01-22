import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tarakite/domain/entity/user.dart';

final userRepositoryProvider = Provider((ref) => UserRepository()..init());

class UserRepository {
  final _db = FirebaseFirestore.instance;
  late final CollectionReference _usersRef;

  void init() {
    _usersRef = _db.collection('users');
  }

  Future<User> findById({required String id}) async {
    final doc = await _usersRef.doc(id).get();
    return User.fromJson(_jsonFromSnapshot(doc));
  }

  Future<void> create({required User user}) async {
    await _usersRef.doc(user.id).set(user.toJson());
  }

  Map<String, dynamic> _jsonFromSnapshot<T extends DocumentSnapshot>(T json) {
    return {
      'id': json.id,
      'email': json['email'],
      'name': json['name'],
    };
  }
}
