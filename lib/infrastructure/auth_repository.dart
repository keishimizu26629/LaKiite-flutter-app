import 'package:firebase_auth/firebase_auth.dart';
import '../domain/interfaces/i_auth_repository.dart';
import '../domain/interfaces/i_user_repository.dart';
import '../domain/entity/user.dart';

class AuthRepository implements IAuthRepository {
  final FirebaseAuth _auth;
  final IUserRepository _userRepository;

  AuthRepository(this._auth, this._userRepository);

  @override
  Stream<UserModel?> authStateChanges() async* {
    await for (final user in _auth.authStateChanges()) {
      if (user == null) {
        yield null;
      } else {
        final userModel = await _userRepository.getUser(user.uid);
        yield userModel;
      }
    }
  }

  @override
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        return await _userRepository.getUser(userCredential.user!.uid);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel?> signUp(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        final userModel = UserModel.create(
          id: userCredential.user!.uid,
          name: name,
        );
        await _userRepository.createUser(userModel);
        return userModel;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
