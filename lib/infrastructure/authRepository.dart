import 'package:firebase_auth/firebase_auth.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../domain/interfaces/i_auth_repository.dart';

final authRepositoryProvider =
    Provider<IauthRepository>((_) => AuthRepository());

class AuthRepository implements IauthRepository {
  final auth = FirebaseAuth.instance;

  @override
  Future<void> logIn({required String email, required String password}) async {}

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
      default:
        return '不明なエラーです';
    }
  }
}
