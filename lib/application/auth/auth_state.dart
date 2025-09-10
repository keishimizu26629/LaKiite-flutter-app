import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entity/user.dart';

part 'auth_state.freezed.dart';

/// アプリケーションの認証状態を表現するクラス
///
/// 状態の種類:
/// - 認証済み状態: ユーザー情報あり
/// - 未認証状態: ユーザー情報なし
/// - ローディング状態: 認証処理中
///
/// 実装:
/// - [freezed]パッケージによるイミュータブルな状態管理
/// - 各状態に応じたファクトリーメソッドを提供
@freezed
class AuthState with _$AuthState {
  const AuthState._();

  /// 認証状態を作成するファクトリーコンストラクタ
  ///
  /// パラメータ:
  /// - [status] 現在の認証ステータス
  /// - [user] ログイン中のユーザー情報(オプション)
  ///
  /// 用途:
  /// - 任意の認証状態を直接作成する場合に使用
  const factory AuthState({
    required AuthStatus status,
    UserModel? user,
  }) = _AuthState;

  /// 認証済み状態を作成するファクトリーメソッド
  ///
  /// パラメータ:
  /// - [user] ログイン中のユーザー情報
  ///
  /// 戻り値:
  /// - [AuthState] 認証済み状態のインスタンス
  ///   - status: [AuthStatus.authenticated]
  ///   - user: 指定されたユーザー情報
  factory AuthState.authenticated(UserModel user) => AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );

  /// 未認証状態を作成するファクトリーメソッド
  ///
  /// 戻り値:
  /// - [AuthState] 未認証状態のインスタンス
  ///   - status: [AuthStatus.unauthenticated]
  ///   - user: null
  factory AuthState.unauthenticated() => const AuthState(
        status: AuthStatus.unauthenticated,
      );

  /// ローディング状態を作成するファクトリーメソッド
  ///
  /// 戻り値:
  /// - [AuthState] ローディング状態のインスタンス
  ///   - status: [AuthStatus.loading]
  ///   - user: null
  factory AuthState.loading() => const AuthState(
        status: AuthStatus.loading,
      );

  /// 認証済みかどうかを判定するゲッター
  ///
  /// 戻り値:
  /// - [bool] 認証済みの場合はtrue、そうでなければfalse
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// 認証状態を表現する列挙型
///
/// 値:
/// - [authenticated]: ユーザーが認証済みの状態
/// - [unauthenticated]: ユーザーが未認証の状態
/// - [loading]: 認証処理中の状態
///
/// 用途:
/// - [AuthState]クラス内で認証状態を表現するために使用
/// - 認証フローの制御に使用
enum AuthStatus { authenticated, unauthenticated, loading }
