import '../../config/app_config.dart';

class FriendInviteShareContent {
  const FriendInviteShareContent({
    required this.url,
    required this.message,
  });

  final Uri url;
  final String message;

  static FriendInviteShareContent create({
    required String searchId,
    required Environment environment,
  }) {
    final normalizedSearchId = searchId.trim();
    if (normalizedSearchId.isEmpty) {
      throw ArgumentError.value(searchId, 'searchId', '検索IDが空です');
    }

    final airbridgeAppName =
        environment == Environment.production ? 'lakiite' : 'lakiitedev';
    final url = Uri.https(
      '$airbridgeAppName.airbridge.io',
      '/friend/search',
      {'searchId': normalizedSearchId},
    );

    return FriendInviteShareContent(
      url: url,
      message: 'LaKiiteで友人になりましょう。\n$url',
    );
  }
}
