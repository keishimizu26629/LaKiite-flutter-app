import 'dart:math';
import '../value/user_id.dart';

/// ユーザー検索用IDを生成するユーティリティクラス
///
/// セキュアな乱数生成器を使用して、
/// 8文字の英数字からなるユーザーIDを生成します。
///
/// 生成されるIDの特徴:
/// - 8文字の固定長
/// - 英大文字、英小文字、数字の組み合わせ
/// - セキュアな乱数を使用
class UserIdGenerator {
  /// ID生成に使用する文字セット
  /// 英大文字、英小文字、数字を含みます
  static const _chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  /// セキュアな乱数生成器
  static final _random = Random.secure();

  /// 8文字のランダムな文字列を生成する
  ///
  /// [_chars]で定義された文字セットから、
  /// セキュアな乱数を使用して8文字をランダムに選択します。
  ///
  /// 返値: 8文字のランダムな英数字文字列
  static String generate() {
    return String.fromCharCodes(
      Iterable.generate(
        8,
        (_) => _chars.codeUnitAt(_random.nextInt(_chars.length)),
      ),
    );
  }

  /// 有効なUserIdインスタンスを生成する
  ///
  /// [generate]メソッドを使用して8文字の文字列を生成し、
  /// それを[UserId]インスタンスに変換します。
  ///
  /// 返値: 生成された文字列から作成された[UserId]インスタンス
  static UserId generateUserId() {
    return UserId(generate());
  }
}
