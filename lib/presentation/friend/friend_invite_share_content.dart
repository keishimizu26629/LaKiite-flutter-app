class FriendInviteShareContent {
  const FriendInviteShareContent({
    required this.url,
    required this.message,
  });

  final Uri url;
  final String message;

  static FriendInviteShareContent create({
    required Uri inviteUrl,
    required String inviterName,
  }) {
    if (!inviteUrl.hasScheme) {
      throw ArgumentError.value(inviteUrl, 'inviteUrl', '招待URLが不正です');
    }
    final normalizedInviterName = inviterName.trim();
    if (normalizedInviterName.isEmpty) {
      throw ArgumentError.value(inviterName, 'inviterName', '招待者名が空です');
    }

    return FriendInviteShareContent(
      url: inviteUrl,
      message: 'LaKiite（ラキーテ）に招待されています！\n'
          'インストールして$normalizedInviterNameさんと友達になりましょう！\n'
          '$inviteUrl',
    );
  }
}
