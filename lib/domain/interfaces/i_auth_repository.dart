import 'package:tarakite/domain/entity/user.dart';

abstract class IAuthRepository {
  Future<UserModel?> signIn(String email, String password);
  Future<void> signOut();
  Future<UserModel?> signUp(String email, String password, String name);
  Stream<UserModel?> authStateChanges();
}
