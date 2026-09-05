import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/interfaces/i_growth_analytics.dart';

class RecordingGrowthAnalytics implements IGrowthAnalytics {
  final signUpAuthMethods = <GrowthAuthMethod>[];
  final inviteLinkSurfaces = <FriendInviteSurface>[];
  var inviteShareSheetOpenedCount = 0;
  final inviteOpenTransports = <FriendInviteLinkTransport>[];
  var friendRequestAcceptedCount = 0;
  final scheduleCreatedCalls = <ScheduleCreatedCall>[];
  final reactionSentCalls = <ReactionSentCall>[];

  @override
  void trackSignUpCompleted({required GrowthAuthMethod authMethod}) {
    signUpAuthMethods.add(authMethod);
  }

  @override
  void trackFriendInviteLinkCreated({required FriendInviteSurface surface}) {
    inviteLinkSurfaces.add(surface);
  }

  @override
  void trackFriendInviteShareSheetOpened() {
    inviteShareSheetOpenedCount += 1;
  }

  @override
  void trackFriendInviteOpened({
    required FriendInviteLinkTransport transport,
  }) {
    inviteOpenTransports.add(transport);
  }

  @override
  void trackFriendRequestAccepted() {
    friendRequestAcceptedCount += 1;
  }

  @override
  void trackScheduleCreated({
    required int recipientCount,
    required int sharedListCount,
    required bool isAllDay,
  }) {
    scheduleCreatedCalls.add(
      ScheduleCreatedCall(
        recipientCount: recipientCount,
        sharedListCount: sharedListCount,
        isAllDay: isAllDay,
      ),
    );
  }

  @override
  void trackScheduleReactionSent({
    required ReactionType reactionType,
    required ReactionChangeKind changeKind,
  }) {
    reactionSentCalls.add(
      ReactionSentCall(reactionType: reactionType, changeKind: changeKind),
    );
  }
}

class ScheduleCreatedCall {
  const ScheduleCreatedCall({
    required this.recipientCount,
    required this.sharedListCount,
    required this.isAllDay,
  });

  final int recipientCount;
  final int sharedListCount;
  final bool isAllDay;
}

class ReactionSentCall {
  const ReactionSentCall({
    required this.reactionType,
    required this.changeKind,
  });

  final ReactionType reactionType;
  final ReactionChangeKind changeKind;
}
