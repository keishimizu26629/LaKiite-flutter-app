import '../entity/schedule_reaction.dart';

enum GrowthAuthMethod {
  emailPassword,
}

enum FriendInviteSurface {
  qr,
  share,
}

enum FriendInviteLinkTransport {
  airbridge,
  universalLink,
  customScheme,
}

enum ReactionChangeKind {
  added,
  changed,
}

abstract interface class IGrowthAnalytics {
  void trackSignUpCompleted({required GrowthAuthMethod authMethod});

  void trackFriendInviteLinkCreated({required FriendInviteSurface surface});

  void trackFriendInviteShareSheetOpened();

  void trackFriendInviteOpened({
    required FriendInviteLinkTransport transport,
  });

  void trackFriendRequestAccepted();

  void trackScheduleCreated({
    required int recipientCount,
    required int sharedListCount,
    required bool isAllDay,
  });

  void trackScheduleReactionSent({
    required ReactionType reactionType,
    required ReactionChangeKind changeKind,
  });
}
