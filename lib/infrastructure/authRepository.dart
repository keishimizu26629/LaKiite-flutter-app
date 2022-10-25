import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../domain/interfaces/i_auth_repository.dart';

import '../presentation/bottom_navigation/bottom_navigation.dart';

final authRepositoryProvider =
    Provider<IauthRepository>((_) => AuthRepository());

class AuthRepository implements IauthRepository {
  final auth = FirebaseAuth.instance;

  @override
  Future<void> login({required String email, required String password, required context}) async {
    try {
      await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => BottomNavigationPage()),
        (_) => false
      );
    } on FirebaseAuthException catch (e) {
      throw convertAuthError(e.code);
    }
  }

  @override
  Future<void> signUp({required String email, required String password}) async {
    try {
      await auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw convertAuthError(e.code);
    }
  }

  String convertAuthError(String errorCode) {
    switch (errorCode) {
      case 'invalid-email':
        return 'メールアドレスを正しい形式で入力してください。';
      case "wrong-password":
        return "パスワードが間違っています";
      case "user-not-found":
        return "ユーザーが見つかりません";
      case "user-disabled":
        return "ユーザーが無効です";
      case "too-many-requests":
        return "しばらく待ってからお試し下さい";
      case "weak-password":
        return "パスワードは6文字以上で入力して下さい";
      case "email-already-in-use":
        return "このメールアドレスは既に登録されています";
      default:
        return '不明なエラーです';
    }
  }
}
