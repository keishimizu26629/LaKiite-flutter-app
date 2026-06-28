import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final deepLinkInvitePreferencesProvider = Provider<DeepLinkInvitePreferences>(
  (ref) => const DeepLinkInvitePreferences(),
);

class DeepLinkInvitePreferences {
  const DeepLinkInvitePreferences();

  static const _pendingFriendSearchIdKey = 'pending_friend_invite_search_id';

  Future<String?> getPendingFriendSearchId() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_pendingFriendSearchIdKey);
  }

  Future<void> savePendingFriendSearchId(String searchId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_pendingFriendSearchIdKey, searchId);
  }

  Future<void> clearPendingFriendSearchId() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingFriendSearchIdKey);
  }
}
