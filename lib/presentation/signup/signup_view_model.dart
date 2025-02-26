import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entity/user.dart';
import '../../domain/interfaces/i_user_repository.dart';
import '../../infrastructure/user_repository.dart';
import '../../utils/logger.dart';

final userRepositoryProvider =
    Provider<IUserRepository>((ref) => UserRepository());

final signupViewModelProvider =
    Provider.autoDispose<SignupViewModel>((ref) => SignupViewModel(ref));

class SignupViewModel {
  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SignupViewModel(this._ref);

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('ユーザーの作成に失敗しました');
      }

      final uid = userCredential.user!.uid;
      final userRepository = _ref.read(userRepositoryProvider);

      final userModel = UserModel.create(
        id: uid,
        name: name,
        displayName: displayName,
      );

      await userRepository.createUser(userModel);

      AppLogger.debug('User document created successfully');
    } catch (e) {
      AppLogger.error('Error in signUp: $e');
      rethrow;
    }
  }
}
