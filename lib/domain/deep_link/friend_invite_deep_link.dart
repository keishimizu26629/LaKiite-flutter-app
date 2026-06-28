class FriendInviteDeepLink {
  const FriendInviteDeepLink({required this.searchId});

  static final RegExp _searchIdPattern = RegExp(r'^[a-zA-Z0-9]{8}$');
  static const Set<String> _allowedAirbridgeHosts = {
    'lakiite.airbridge.io',
    'lakiite.abr.ge',
    'lakiitedev.airbridge.io',
    'lakiitedev.abr.ge',
    'invite.lakiite.inoworl.com',
    'invite.lakiite-dev.inoworl.com',
  };
  static const Set<String> _nestedDeepLinkKeys = {
    'airbridge_deeplink',
    'airbridge_deeplink_url',
    'deep_link',
    'deep_link_url',
    'deeplink',
    'deeplink_url',
    'redirect',
    'redirect_url',
    'target_url',
  };

  final String searchId;

  static FriendInviteDeepLink? tryParse(String value) {
    return _tryParse(value.trim(), <String>{});
  }

  static bool isSupportedAirbridgeLink(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && _isSupportedAirbridgeHttps(uri);
  }

  static FriendInviteDeepLink? _tryParse(
    String value,
    Set<String> visitedValues,
  ) {
    if (value.isEmpty ||
        !visitedValues.add(value) ||
        visitedValues.length > 8) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !_isSupportedUri(uri)) {
      return null;
    }

    final searchId = _validSearchId(_extractSearchId(uri));
    if (searchId != null &&
        (_isFriendInvitePath(uri) || _isSupportedAirbridgeHttps(uri))) {
      return FriendInviteDeepLink(searchId: searchId);
    }

    for (final key in _nestedDeepLinkKeys) {
      final nestedValues = uri.queryParametersAll[key] ?? const <String>[];
      for (final nestedValue in nestedValues) {
        final deepLink = _tryParseNestedValue(nestedValue, visitedValues);
        if (deepLink != null) {
          return deepLink;
        }
      }
    }

    return null;
  }

  static FriendInviteDeepLink? _tryParseNestedValue(
    String value,
    Set<String> visitedValues,
  ) {
    for (final candidate in _nestedCandidates(value)) {
      final deepLink = _tryParse(candidate, visitedValues);
      if (deepLink != null) {
        return deepLink;
      }
    }

    return null;
  }

  static Iterable<String> _nestedCandidates(String value) sync* {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return;
    }

    yield trimmed;

    final decoded = _tryDecodeComponent(trimmed);
    if (decoded != null && decoded.isNotEmpty && decoded != trimmed) {
      yield decoded;
    }

    for (final candidate in {trimmed, if (decoded != null) decoded}) {
      if (candidate.isEmpty || candidate.contains('://')) {
        continue;
      }

      final path = candidate.startsWith('/') ? candidate : '/$candidate';
      yield 'https://lakiitedev.airbridge.io$path';
      yield 'https://lakiite.airbridge.io$path';
      yield 'https://invite.lakiite-dev.inoworl.com$path';
      yield 'https://invite.lakiite.inoworl.com$path';
    }
  }

  static String? _tryDecodeComponent(String value) {
    try {
      return Uri.decodeComponent(value).trim();
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static bool _isSupportedUri(Uri uri) {
    if (uri.scheme == 'lakiite' || uri.scheme == 'lakiitedev') {
      return true;
    }

    return _isSupportedAirbridgeHttps(uri);
  }

  static bool _isSupportedAirbridgeHttps(Uri uri) {
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

  static String? _validSearchId(String? searchId) {
    if (searchId == null || !_searchIdPattern.hasMatch(searchId)) {
      return null;
    }

    return searchId;
  }
}
