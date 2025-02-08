class UserId {
  final String value;

  UserId._(this.value);

  factory UserId(String value) {
    if (!isValid(value)) {
      throw ArgumentError('Invalid user ID format');
    }
    return UserId._(value);
  }

  static bool isValid(String value) {
    // 8文字の半角英数字のみを許可
    final regex = RegExp(r'^[a-zA-Z0-9]{8}$');
    return regex.hasMatch(value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
