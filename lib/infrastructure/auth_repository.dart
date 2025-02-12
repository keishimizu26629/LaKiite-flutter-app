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
        // ユーザーデータの取得を最大5回試行
        UserModel? userModel;
        for (var i = 0; i < 5; i++) {
          userModel = await _userRepository.getUser(user.uid);
          if (userModel != null) {
            yield userModel;
            break;
          }
          // 最後の試行以外は待機
          if (i < 4) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
        // ユーザーデータが取得できなかった場合
        if (userModel == null) {
          yield null;
        }
      }
    }
  }

  @override
  Future<UserModel?> signIn(String email, String password) async {
    try {
      // 1. Firebase認証でサインイン
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        return null;
      }

      // 2. ユーザーデータを取得(最大5回試行)
      UserModel? userModel;
      for (var i = 0; i < 5; i++) {
        userModel = await _userRepository.getUser(userCredential.user!.uid);
        if (userModel != null) break;
        // 最後の試行以外は待機
        if (i < 4) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (userModel == null) {
        // ユーザーデータが見つからない場合は認証をクリア
        await _auth.signOut();
        throw Exception('ユーザーデータが見つかりません');
      }

      return userModel;
    } catch (e) {
      // エラーが発生した場合は認証をクリア
      await _auth.signOut();
      rethrow;
    }
  }

  @override
  Future<UserModel?> signUp(String email, String password, String name) async {
    UserCredential? userCredential;
    try {
      // 1. Firebaseで認証アカウントを作成
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('認証アカウントの作成に失敗しました');
      }

      // 2. ユーザーモデルを作成
      final userModel = UserModel.create(
        id: userCredential.user!.uid,
        name: name,
      );

      try {
        // 3. Firestoreにユーザーデータを保存
        await _userRepository.createUser(userModel);
      } catch (e) {
        // Firestoreへの保存に失敗した場合、認証アカウントを削除
        await userCredential.user!.delete();
        throw Exception('ユーザーデータの作成に失敗しました: ${e.toString()}');
      }

      // 4. ユーザーデータが確実に保存されたことを確認(最大5回試行)
      UserModel? savedUser;
      for (var i = 0; i < 5; i++) {
        savedUser = await _userRepository.getUser(userModel.id);
        if (savedUser != null) break;
        // 最後の試行以外は待機
        if (i < 4) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (savedUser == null) {
        throw Exception('ユーザーデータの作成を確認できませんでした');
      }

      return savedUser;
    } catch (e) {
      // エラーが発生した場合、作成した認証アカウントを削除
      if (userCredential?.user != null) {
        await userCredential!.user!.delete();
      }

      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw Exception('このメールアドレスは既に使用されています');
          case 'invalid-email':
            throw Exception('無効なメールアドレスです');
          case 'operation-not-allowed':
            throw Exception('メール/パスワード認証が無効になっています');
          case 'weak-password':
            throw Exception('パスワードが脆弱です');
          default:
            throw Exception('認証エラーが発生しました: ${e.message}');
        }
      }
      throw Exception('アカウント作成に失敗しました: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
