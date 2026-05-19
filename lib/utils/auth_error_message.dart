import 'package:firebase_auth/firebase_auth.dart';

class UserFacingException implements Exception {
  const UserFacingException(this.message);

  final String message;

  @override
  String toString() => message;
}

String signInErrorMessage(Object? error) {
  if (error is UserFacingException) {
    return error.message;
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'パスワードが間違っています';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'user-not-found':
        return 'メールアドレスまたはパスワードが間違っています';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'too-many-requests':
        return 'ログイン試行回数が多すぎます。しばらく時間をおいて再度お試しください';
      case 'network-request-failed':
        return 'ネットワーク接続を確認してから再度お試しください';
      default:
        return 'ログインに失敗しました。入力内容を確認してください';
    }
  }

  final message = _stripExceptionPrefix(error?.toString().trim() ?? '');
  if (message.isEmpty || _looksLikeRawFirebaseMessage(message)) {
    return 'ログインに失敗しました。入力内容を確認してください';
  }
  return message;
}

String signUpErrorMessage(Object? error) {
  if (error is UserFacingException) {
    return error.message;
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'operation-not-allowed':
        return 'メール/パスワード認証が無効になっています';
      case 'weak-password':
        return 'パスワードは6文字以上で入力してください';
      case 'network-request-failed':
        return 'ネットワーク接続を確認してから再度お試しください';
      default:
        return 'アカウント作成に失敗しました。入力内容を確認してください';
    }
  }

  final message = _stripExceptionPrefix(error?.toString().trim() ?? '');
  if (message.isEmpty || _looksLikeRawFirebaseMessage(message)) {
    return 'アカウント作成に失敗しました。入力内容を確認してください';
  }
  return message;
}

String _stripExceptionPrefix(String message) {
  return message.replaceFirst(
    RegExp(r'^(Exception|ArgumentError):\s*'),
    '',
  );
}

bool _looksLikeRawFirebaseMessage(String message) {
  return message.contains('[firebase_auth/') ||
      message.contains('FirebaseAuthException') ||
      message.contains('auth credential');
}
