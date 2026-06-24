class FriendInviteDeepLink {
  const FriendInviteDeepLink({required this.searchId});

  static final RegExp _searchIdPattern = RegExp(r'^[a-zA-Z0-9]{8}$');
  static const Set<String> _allowedAirbridgeHosts = {
    'lakiite.airbridge.io',
    'lakiite.abr.ge',
    'lakiitedev.airbridge.io',
    'lakiitedev.abr.ge',
  };

  final String searchId;

  static FriendInviteDeepLink? tryParse(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !_isSupportedUri(uri) || !_isFriendInvitePath(uri)) {
      return null;
    }

    final searchId = _extractSearchId(uri);
    if (searchId == null || !_searchIdPattern.hasMatch(searchId)) {
      return null;
    }

    return FriendInviteDeepLink(searchId: searchId);
  }

  static bool _isSupportedUri(Uri uri) {
    if (uri.scheme == 'lakiite' || uri.scheme == 'lakiitedev') {
      return true;
    }

    return uri.scheme == 'https' && _allowedAirbridgeHosts.contains(uri.host);
  }

  static bool _isFriendInvitePath(Uri uri) {
    final segments = [
      if ((uri.scheme == 'lakiite' || uri.scheme == 'lakiitedev') &&
          uri.host.isNotEmpty)
        uri.host,
      ...uri.pathSegments,
    ];

    if (segments.length >= 2 &&
        segments[0] == 'friend' &&
        segments[1] == 'search') {
      return true;
    }

    return segments.isNotEmpty && segments[0] == 'invite';
  }

  static String? _extractSearchId(Uri uri) {
    final searchId = uri.queryParameters['searchId'];
    if (searchId != null && searchId.trim().isNotEmpty) {
      return searchId.trim();
    }

    final snakeCaseSearchId = uri.queryParameters['search_id'];
    if (snakeCaseSearchId != null && snakeCaseSearchId.trim().isNotEmpty) {
      return snakeCaseSearchId.trim();
    }

    return null;
  }
}
