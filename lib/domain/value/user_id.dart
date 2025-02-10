/// ユーザー検索用のID値オブジェクト
///
/// 8文字の半角英数字で構成される検索用IDを表現します。
/// 不変(イミュータブル)なValue Objectとして実装されています。
///
/// 制約:
/// - 8文字の固定長
/// - 半角英数字のみ使用可能
class UserId {
  /// ユーザーIDの実値
  final String value;

  /// プライベートコンストラクタ
  ///
  /// 直接のインスタンス化を防ぎ、ファクトリーコンストラクタを通じて
  /// バリデーション済みのインスタンスのみを生成可能にします。
  UserId._(this.value);

  /// UserIdを生成するファクトリーコンストラクタ
  ///
  /// [value] 8文字の半角英数字からなるユーザーID文字列
  ///
  /// 不正なフォーマットの場合は[ArgumentError]をスローします。
  /// ```dart
  /// final userId = UserId('abc12345'); // 不正なフォーマット: 9文字
  /// final userId = UserId('abcd1234'); // OK: 8文字の半角英数字
  /// ```
  factory UserId(String value) {
    if (!isValid(value)) {
      throw ArgumentError('Invalid user ID format');
    }
    return UserId._(value);
  }

  /// ユーザーID文字列が有効なフォーマットかを検証する
  ///
  /// [value] 検証対象のユーザーID文字列
  ///
  /// 以下の条件を満たす場合にtrueを返します:
  /// - 8文字の固定長
  /// - 半角英数字のみで構成
  static bool isValid(String value) {
    // 8文字の半角英数字のみを許可
    final regex = RegExp(r'^[a-zA-Z0-9]{8}$');
    return regex.hasMatch(value);
  }

  /// 等価性の比較
  ///
  /// 同じ値を持つUserIdインスタンスは等しいとみなされます。
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  /// ハッシュコード
  ///
  /// 等価性の比較と整合性のあるハッシュコードを生成します。
  @override
  int get hashCode => value.hashCode;

  /// 文字列表現
  ///
  /// UserIdの値をそのまま文字列として返します。
  @override
  String toString() => value;
}
