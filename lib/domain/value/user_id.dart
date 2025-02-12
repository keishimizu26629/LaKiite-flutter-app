class UserId {
  final String value;

  UserId._(this.value);

  factory UserId(String value) {
    if (!isValidFormat(value)) {
      throw ArgumentError('Invalid user ID format');
    }
    return UserId._(value);
  }

  static bool isValidFormat(String value) {
    // 8文字の英数字のみを許可
    return RegExp(r'^[a-zA-Z0-9]{8}$').hasMatch(value);
  }

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserId && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
