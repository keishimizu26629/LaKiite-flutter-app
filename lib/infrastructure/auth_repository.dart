import 'package:firebase_auth/firebase_auth.dart';
import '../domain/interfaces/i_auth_repository.dart';
import '../domain/interfaces/i_user_repository.dart';
import '../domain/entity/user.dart';
import '../utils/auth_error_message.dart';
import '../utils/logger.dart';

class AuthRepository implements IAuthRepository {
  AuthRepository(this._auth, this._userRepository);
  final FirebaseAuth _auth;
  final IUserRepository _userRepository;

  @override
  Stream<UserModel?> authStateChanges() async* {
    await for (final user in _auth.authStateChanges()) {
      AppLogger.debugOnly('authStateChanges受信: firebaseUser=${user?.uid}');
      if (user == null) {
        yield null;
      } else {
        // ユーザーデータの取得を最大5回試行
        UserModel? userModel;
        for (var i = 0; i < 5; i++) {
          AppLogger.debugOnly(
              'authStateChanges.getUser試行: userId=${user.uid}, attempt=${i + 1}');
          userModel = await _userRepository.getUser(user.uid);
          if (userModel != null) {
            AppLogger.debugOnly(
                'authStateChanges.getUser成功: userId=${user.uid}');
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
          AppLogger.warningOnly(
              'authStateChanges.getUser失敗: userId=${user.uid}');
          yield null;
        }
      }
    }
  }

  @override
  Future<UserModel?> signIn(String email, String password) async {
    try {
      AppLogger.debugOnly('AuthRepository.signIn開始: email=$email');
      // 1. Firebase認証でサインイン
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        AppLogger.warningOnly(
            'AuthRepository.signIn: userCredential.userがnull');
        return null;
      }

      AppLogger.debugOnly(
          'AuthRepository.signIn認証成功: firebaseUid=${userCredential.user!.uid}');

      // 2. ユーザーデータを取得(最大5回試行)
      UserModel? userModel;
      for (var i = 0; i < 5; i++) {
        AppLogger.debugOnly(
            'AuthRepository.signIn.getUser試行: userId=${userCredential.user!.uid}, attempt=${i + 1}');
        userModel = await _userRepository.getUser(userCredential.user!.uid);
        if (userModel != null) break;
        // 最後の試行以外は待機
        if (i < 4) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (userModel == null) {
        // ユーザーデータが見つからない場合は認証をクリア
        AppLogger.warningOnly(
            'AuthRepository.signIn失敗: Firestoreにユーザーデータなし userId=${userCredential.user!.uid}');
        await _auth.signOut();
        throw Exception('ユーザーデータが見つかりません');
      }

      AppLogger.debugOnly('AuthRepository.signIn完了: userId=${userModel.id}');
      return userModel;
    } catch (e) {
      // エラーが発生した場合は認証をクリア
      AppLogger.errorOnly('AuthRepository.signIn例外', e);
      await _auth.signOut();
      if (e is FirebaseAuthException) {
        throw UserFacingException(signInErrorMessage(e));
      }
      rethrow;
    }
  }

  @override
  Future<UserModel?> signUp(String email, String password, String name) async {
    UserCredential? userCredential;
    try {
      AppLogger.debugOnly('AuthRepository.signUp開始: email=$email, name=$name');
      // 1. Firebaseで認証アカウントを作成
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        AppLogger.warningOnly(
            'AuthRepository.signUp: userCredential.userがnull');
        throw Exception('認証アカウントの作成に失敗しました');
      }

      AppLogger.debugOnly(
          'AuthRepository.signUp認証作成成功: firebaseUid=${userCredential.user!.uid}');

      // 2. ユーザーモデルを作成
      final userModel = UserModel.create(
        id: userCredential.user!.uid,
        name: name,
      );

      try {
        // 3. Firestoreにユーザーデータを保存
        AppLogger.debugOnly(
            'AuthRepository.signUp.createUser開始: userId=${userModel.id}');
        await _userRepository.createUser(userModel);
        AppLogger.debugOnly(
            'AuthRepository.signUp.createUser完了: userId=${userModel.id}');
      } catch (e) {
        // Firestoreへの保存に失敗した場合、認証アカウントを削除
        AppLogger.errorOnly('AuthRepository.signUp.createUser失敗', e);
        await userCredential.user!.delete();
        throw Exception('ユーザーデータの作成に失敗しました: ${e.toString()}');
      }

      // 4. ユーザーデータが確実に保存されたことを確認(最大5回試行)
      UserModel? savedUser;
      for (var i = 0; i < 5; i++) {
        AppLogger.debugOnly(
            'AuthRepository.signUp.getUser試行: userId=${userModel.id}, attempt=${i + 1}');
        savedUser = await _userRepository.getUser(userModel.id);
        if (savedUser != null) break;
        // 最後の試行以外は待機
        if (i < 4) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (savedUser == null) {
        AppLogger.warningOnly(
            'AuthRepository.signUp失敗: 作成確認できず userId=${userModel.id}');
        throw Exception('ユーザーデータの作成を確認できませんでした');
      }

      AppLogger.debugOnly('AuthRepository.signUp完了: userId=${savedUser.id}');
      return savedUser;
    } catch (e) {
      // エラーが発生した場合、作成した認証アカウントを削除
      AppLogger.errorOnly('AuthRepository.signUp例外', e);
      if (userCredential?.user != null) {
        await userCredential!.user!.delete();
      }

      if (e is FirebaseAuthException) {
        throw UserFacingException(signUpErrorMessage(e));
      }
      throw UserFacingException(signUpErrorMessage(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<bool> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final userId = user.uid;

      // 1. Firestoreからユーザーデータを削除
      await _userRepository.deleteUser(userId);

      try {
        // 2. Firebase Authからユーザーを削除
        await user.delete();
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
          // 再認証が必要な場合はエラーをスロー
          throw Exception('セキュリティのため再認証が必要です。一度ログアウトして再度ログインした後に操作してください。');
        }
        rethrow;
      }

      return true;
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'requires-recent-login':
            throw Exception('セキュリティのため再認証が必要です。一度ログアウトして再度ログインした後に操作してください。');
          default:
            throw Exception('アカウント削除エラー: ${e.message}');
        }
      }
      throw Exception('アカウント削除に失敗しました: $e');
    }
  }

  @override
  Future<bool> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      if (user.email == null) {
        throw Exception('メールアドレスが取得できません');
      }

      // パスワードで再認証
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      return true;
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            throw Exception('パスワードが正しくありません');
          case 'invalid-credential':
            throw Exception('認証情報が無効です');
          case 'user-mismatch':
            throw Exception('ユーザーが一致しません');
          case 'user-not-found':
            throw Exception('ユーザーが見つかりません');
          case 'invalid-verification-code':
            throw Exception('認証コードが無効です');
          case 'invalid-verification-id':
            throw Exception('認証IDが無効です');
          default:
            throw Exception('再認証エラー: ${e.message}');
        }
      }
      throw Exception('再認証に失敗しました: $e');
    }
  }

  @override
  Future<bool> deleteAccountWithReauth(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final userId = user.uid;

      // 1. 再認証を実行
      await reauthenticateWithPassword(password);

      // 2. Firestoreからユーザーデータを削除
      await _userRepository.deleteUser(userId);

      // 3. Firebase Authからユーザーを削除
      await user.delete();

      return true;
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'requires-recent-login':
            throw Exception('セキュリティのため再認証が必要です。一度ログアウトして再度ログインした後に操作してください。');
          default:
            throw Exception('アカウント削除エラー: ${e.message}');
        }
      }
      throw Exception('アカウント削除に失敗しました: $e');
    }
  }
}
