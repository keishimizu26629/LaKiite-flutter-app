String maskNotificationToken(String? token) {
  if (token == null || token.isEmpty) {
    return '未取得';
  }

  if (token.length <= 4) {
    final splitIndex = token.length ~/ 2;
    return '${token.substring(0, splitIndex)}...${token.substring(splitIndex)}';
  }

  const visibleLength = 6;
  if (token.length <= visibleLength * 2) {
    final splitIndex = token.length ~/ 2;
    return '${token.substring(0, splitIndex)}...${token.substring(splitIndex)}';
  }

  return '${token.substring(0, visibleLength)}...${token.substring(token.length - visibleLength)}';
}
