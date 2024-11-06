import 'package:tarakite/domain/entity/user.dart';

abstract class IAuthRepository {
  Future<AppUser?> signIn(String email, String password);
  Future<void> signOut();
  Future<AppUser?> signUp(String email, String password, String userId);
  Stream<AppUser?> authStateChanges();
}