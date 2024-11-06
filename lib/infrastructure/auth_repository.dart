import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entity/user.dart';
import '../../domain/interfaces/i_auth_repository.dart';

class AuthRepository implements IAuthRepository {
  final firebase.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository(this._firebaseAuth, this._firestore);

  @override
  Future<AppUser?> signIn(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _getUserFromFirestore(userCredential.user?.uid);
  }

  @override
  Future<AppUser?> signUp(String email, String password, String userId) async {
    final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final appUser = AppUser(
      id: userCredential.user!.uid,
      profile: Profile(name: '新しいユーザー'),
      friends: [],
      groups: [],
    );

    await _firestore.collection('users').doc(appUser.id).set(appUser.toJson());
    return appUser;
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) {
      if (firebaseUser != null) {
        return _getUserFromFirestore(firebaseUser.uid);
      } else {
        return null;
      }
    });
  }

  Future<AppUser?> _getUserFromFirestore(String? uid) async {
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return AppUser.fromJson(doc.data()!);
    } else {
      return null;
    }
  }
}