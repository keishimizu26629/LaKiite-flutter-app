import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entity/user.dart';

final signupViewModelProvider = Provider.autoDispose((ref) => SignupViewModel(ref));

class SignupViewModel {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SignupViewModel(this._ref);

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // Firebase Authenticationでユーザーを作成
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // UserModelを作成
        final userModel = UserModel.create(
          id: userCredential.user!.uid,
          name: name,
        );

        // Firestoreにユーザーデータを保存
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(userModel.toFirestore());
      }
    } catch (e) {
      rethrow;
    }
  }
}
