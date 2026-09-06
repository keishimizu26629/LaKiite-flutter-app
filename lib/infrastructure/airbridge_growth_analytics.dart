import 'dart:io';

import 'package:airbridge_flutter_sdk/airbridge_flutter_sdk.dart';

import '../domain/entity/schedule_reaction.dart';
import '../domain/interfaces/i_growth_analytics.dart';
import '../utils/logger.dart';

typedef AirbridgeEventSender = void Function({
  required String category,
  required Map<String, dynamic> customAttributes,
});
typedef AirbridgeTrackingStarter = void Function();

class AirbridgeGrowthAnalytics implements IGrowthAnalytics {
  AirbridgeGrowthAnalytics({AirbridgeEventSender? sender})
      : _sender = sender ?? _sendToAirbridge;

  static const _schemaVersion = 1;

  final AirbridgeEventSender _sender;

  @override
  void trackSignUpCompleted({required GrowthAuthMethod authMethod}) {
    _track(
      category: 'sign_up_completed',
      attributes: {'auth_method': authMethod.analyticsValue},
    );
  }

  @override
  void trackFriendInviteLinkCreated({required FriendInviteSurface surface}) {
    _track(
      category: 'friend_invite_link_created',
      attributes: {'surface': surface.analyticsValue},
    );
  }

  @override
  void trackFriendInviteShareSheetOpened() {
    _track(
      category: 'friend_invite_share_sheet_opened',
      attributes: const {'surface': 'share'},
    );
  }

  @override
  void trackFriendInviteOpened({
    required FriendInviteLinkTransport transport,
  }) {
    _track(
      category: 'friend_invite_opened',
      attributes: {'link_transport': transport.analyticsValue},
    );
  }

  @override
  void trackFriendRequestAccepted() {
    _track(
      category: 'friend_request_accepted',
      attributes: const {'entry_point': 'notification'},
    );
  }

  @override
  void trackScheduleCreated({
    required int recipientCount,
    required int sharedListCount,
    required bool isAllDay,
  }) {
    _track(
      category: 'schedule_created',
      attributes: {
        'is_shared': recipientCount > 0 || sharedListCount > 0,
        'recipient_count_bucket': _recipientCountBucket(recipientCount),
        'shared_list_count_bucket': _sharedListCountBucket(sharedListCount),
        'is_all_day': isAllDay,
      },
    );
  }

  @override
  void trackScheduleReactionSent({
    required ReactionType reactionType,
    required ReactionChangeKind changeKind,
  }) {
    _track(
      category: 'schedule_reaction_sent',
      attributes: {
        'reaction_type': reactionType.analyticsValue,
        'change_kind': changeKind.analyticsValue,
      },
    );
  }

  void _track({
    required String category,
    required Map<String, dynamic> attributes,
  }) {
    try {
      _sender(
        category: category,
        customAttributes: Map.unmodifiable({
          'event_schema_version': _schemaVersion,
          ...attributes,
        }),
      );
    } catch (_) {
      AppLogger.warning(
        'Growth analytics event transmission failed: $category',
      );
    }
  }

  static void _sendToAirbridge({
    required String category,
    required Map<String, dynamic> customAttributes,
  }) {
    Airbridge.trackEvent(
      category: category,
      customAttributes: customAttributes,
    );
  }
}

class NoopGrowthAnalytics implements IGrowthAnalytics {
  const NoopGrowthAnalytics();

  @override
  void trackSignUpCompleted({required GrowthAuthMethod authMethod}) {}

  @override
  void trackFriendInviteLinkCreated({required FriendInviteSurface surface}) {}

  @override
  void trackFriendInviteShareSheetOpened() {}

  @override
  void trackFriendInviteOpened({
    required FriendInviteLinkTransport transport,
  }) {}

  @override
  void trackFriendRequestAccepted() {}

  @override
  void trackScheduleCreated({
    required int recipientCount,
    required int sharedListCount,
    required bool isAllDay,
  }) {}

  @override
  void trackScheduleReactionSent({
    required ReactionType reactionType,
    required ReactionChangeKind changeKind,
  }) {}
}

IGrowthAnalytics createGrowthAnalytics({
  bool testMode = const bool.fromEnvironment(
    'TEST_MODE',
    defaultValue: false,
  ),
  bool? flutterTest,
  bool useFirebaseEmulator = const bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: false,
  ),
  AirbridgeEventSender? sender,
}) {
  if (_isTrackingDisabled(
    testMode: testMode,
    flutterTest: flutterTest,
    useFirebaseEmulator: useFirebaseEmulator,
  )) {
    return const NoopGrowthAnalytics();
  }
  return AirbridgeGrowthAnalytics(sender: sender);
}

/// SDK設定で停止しているAirbridge追跡を、通常環境だけ開始する。
void startAirbridgeTrackingIfAllowed({
  bool testMode = const bool.fromEnvironment(
    'TEST_MODE',
    defaultValue: false,
  ),
  bool? flutterTest,
  bool useFirebaseEmulator = const bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: false,
  ),
  AirbridgeTrackingStarter? starter,
}) {
  if (_isTrackingDisabled(
    testMode: testMode,
    flutterTest: flutterTest,
    useFirebaseEmulator: useFirebaseEmulator,
  )) {
    return;
  }

  try {
    (starter ?? Airbridge.startTracking)();
  } catch (_) {
    AppLogger.warning('Airbridge tracking could not be started');
  }
}

bool _isTrackingDisabled({
  required bool testMode,
  required bool? flutterTest,
  required bool useFirebaseEmulator,
}) {
  final isFlutterTest =
      flutterTest ?? Platform.environment['FLUTTER_TEST'] == 'true';
  return testMode || isFlutterTest || useFirebaseEmulator;
}

String _recipientCountBucket(int count) {
  if (count <= 0) return '0';
  if (count == 1) return '1';
  if (count <= 5) return '2_5';
  return '6_plus';
}

String _sharedListCountBucket(int count) {
  if (count <= 0) return '0';
  if (count == 1) return '1';
  if (count <= 3) return '2_3';
  return '4_plus';
}

extension on GrowthAuthMethod {
  String get analyticsValue => switch (this) {
        GrowthAuthMethod.emailPassword => 'email_password',
      };
}

extension on FriendInviteSurface {
  String get analyticsValue => switch (this) {
        FriendInviteSurface.qr => 'qr',
        FriendInviteSurface.share => 'share',
      };
}

extension on FriendInviteLinkTransport {
  String get analyticsValue => switch (this) {
        FriendInviteLinkTransport.airbridge => 'airbridge',
        FriendInviteLinkTransport.universalLink => 'universal_link',
        FriendInviteLinkTransport.customScheme => 'custom_scheme',
      };
}

extension on ReactionChangeKind {
  String get analyticsValue => switch (this) {
        ReactionChangeKind.added => 'added',
        ReactionChangeKind.changed => 'changed',
      };
}

extension on ReactionType {
  String get analyticsValue => switch (this) {
        ReactionType.going => 'going',
        ReactionType.thinking => 'thinking',
      };
}
