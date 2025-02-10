import 'package:tarakite/domain/entity/user.dart';

/// 認証機能を提供するリポジトリのインターフェース
///
/// アプリケーションの認証に関する以下の機能を定義します:
/// - ユーザーのサインイン
/// - ユーザーのサインアウト
/// - 新規ユーザー登録
/// - 認証状態の監視
///
/// このインターフェースの実装クラスは、
/// 具体的な認証基盤(例:Firebase Authentication)と
/// アプリケーションを橋渡しする役割を果たします。
abstract class IAuthRepository {
  /// メールアドレスとパスワードでサインインを行う
  ///
  /// [email] サインインに使用するメールアドレス
  /// [password] サインインに使用するパスワード
  ///
  /// 返値: サインイン成功時は[UserModel]、失敗時はnull
  Future<UserModel?> signIn(String email, String password);

  /// 現在のユーザーをサインアウトする
  ///
  /// サインアウト処理が完了するまで待機します。
  Future<void> signOut();

  /// 新規ユーザー登録を行う
  ///
  /// [email] 登録するメールアドレス
  /// [password] 設定するパスワード
  /// [name] ユーザー名
  ///
  /// 返値: 登録成功時は作成された[UserModel]、失敗時はnull
  Future<UserModel?> signUp(String email, String password, String name);

  /// 認証状態の変更を監視するStreamを提供する
  ///
  /// 返値: 認証状態が変更されるたびに[UserModel](または未認証時はnull)を
  /// 発行するStream
  Stream<UserModel?> authStateChanges();
}
