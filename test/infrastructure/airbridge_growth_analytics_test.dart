import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/interfaces/i_growth_analytics.dart';
import 'package:lakiite/infrastructure/airbridge_growth_analytics.dart';

void main() {
  group('AirbridgeGrowthAnalytics', () {
    late List<_RecordedEvent> events;
    late AirbridgeGrowthAnalytics analytics;

    setUp(() {
      events = [];
      analytics = AirbridgeGrowthAnalytics(
        sender: ({
          required String category,
          required Map<String, dynamic> customAttributes,
        }) {
          events.add(
            _RecordedEvent(
              category: category,
              customAttributes: customAttributes,
            ),
          );
        },
      );
    });

    test('登録完了は固定categoryと認証方式だけを送る', () {
      analytics.trackSignUpCompleted(
        authMethod: GrowthAuthMethod.emailPassword,
      );

      expect(events.single.category, 'sign_up_completed');
      expect(events.single.customAttributes, {
        'event_schema_version': 1,
        'auth_method': 'email_password',
      });
    });

    test('招待リンク作成は表示面だけを送る', () {
      analytics.trackFriendInviteLinkCreated(
        surface: FriendInviteSurface.qr,
      );

      expect(events.single.category, 'friend_invite_link_created');
      expect(events.single.customAttributes, {
        'event_schema_version': 1,
        'surface': 'qr',
      });
    });

    test('共有UI完了は共有面だけを送る', () {
      analytics.trackFriendInviteShareSheetOpened();

      expect(events.single.category, 'friend_invite_share_sheet_opened');
      expect(events.single.customAttributes, {
        'event_schema_version': 1,
        'surface': 'share',
      });
    });

    test('招待openはcategoricalなtransportだけを送る', () {
      analytics.trackFriendInviteOpened(
        transport: FriendInviteLinkTransport.universalLink,
      );

      expect(events.single.category, 'friend_invite_opened');
      expect(events.single.customAttributes, {
        'event_schema_version': 1,
        'link_transport': 'universal_link',
      });
    });

    test('友達申請承認は固定entry pointだけを送る', () {
      analytics.trackFriendRequestAccepted();

      expect(events.single.category, 'friend_request_accepted');
      expect(events.single.customAttributes, {
        'event_schema_version': 1,
        'entry_point': 'notification',
      });
    });

    test('予定作成は共有人数とリスト数をbucket化して送る', () {
      analytics.trackScheduleCreated(
        recipientCount: 3,
        sharedListCount: 2,
        isAllDay: true,
      );

      expect(events.single.category, 'schedule_created');
      expect(events.single.customAttributes, {
        'event_schema_version': 1,
        'is_shared': true,
        'recipient_count_bucket': '2_5',
        'shared_list_count_bucket': '2_3',
        'is_all_day': true,
      });
    });

    test('非共有予定は0 bucketとして送る', () {
      analytics.trackScheduleCreated(
        recipientCount: 0,
        sharedListCount: 0,
        isAllDay: false,
      );

      expect(events.single.customAttributes, {
        'event_schema_version': 1,
        'is_shared': false,
        'recipient_count_bucket': '0',
        'shared_list_count_bucket': '0',
        'is_all_day': false,
      });
    });

    test('reaction送信は種別と変更種別だけを送る', () {
      analytics.trackScheduleReactionSent(
        reactionType: ReactionType.going,
        changeKind: ReactionChangeKind.changed,
      );

      expect(events.single.category, 'schedule_reaction_sent');
      expect(events.single.customAttributes, {
        'event_schema_version': 1,
        'reaction_type': 'going',
        'change_kind': 'changed',
      });
    });

    test('transport例外をbusiness actionへ伝播させない', () {
      final failingAnalytics = AirbridgeGrowthAnalytics(
        sender: ({
          required String category,
          required Map<String, dynamic> customAttributes,
        }) {
          throw StateError('transport failed');
        },
      );

      expect(
        () => failingAnalytics.trackFriendRequestAccepted(),
        returnsNormally,
      );
    });
  });

  group('createGrowthAnalytics', () {
    test('TEST_MODEではNo-opにする', () {
      final analytics = createGrowthAnalytics(
        testMode: true,
        flutterTest: false,
        useFirebaseEmulator: false,
      );

      expect(analytics, isA<NoopGrowthAnalytics>());
    });

    test('FLUTTER_TESTではNo-opにする', () {
      final analytics = createGrowthAnalytics(
        testMode: false,
        flutterTest: true,
        useFirebaseEmulator: false,
      );

      expect(analytics, isA<NoopGrowthAnalytics>());
    });

    test('Firebase EmulatorではNo-opにする', () {
      final analytics = createGrowthAnalytics(
        testMode: false,
        flutterTest: false,
        useFirebaseEmulator: true,
      );

      expect(analytics, isA<NoopGrowthAnalytics>());
    });

    test('通常環境ではAirbridge transportを使う', () {
      final events = <_RecordedEvent>[];
      final analytics = createGrowthAnalytics(
        testMode: false,
        flutterTest: false,
        useFirebaseEmulator: false,
        sender: ({
          required String category,
          required Map<String, dynamic> customAttributes,
        }) {
          events.add(
            _RecordedEvent(
              category: category,
              customAttributes: customAttributes,
            ),
          );
        },
      );

      analytics.trackFriendRequestAccepted();

      expect(analytics, isA<AirbridgeGrowthAnalytics>());
      expect(events.single.category, 'friend_request_accepted');
    });
  });

  group('startAirbridgeTrackingIfAllowed', () {
    test('testまたはFirebase EmulatorではSDK追跡を開始しない', () {
      var startCount = 0;

      startAirbridgeTrackingIfAllowed(
        testMode: true,
        flutterTest: false,
        useFirebaseEmulator: false,
        starter: () => startCount += 1,
      );
      startAirbridgeTrackingIfAllowed(
        testMode: false,
        flutterTest: true,
        useFirebaseEmulator: false,
        starter: () => startCount += 1,
      );
      startAirbridgeTrackingIfAllowed(
        testMode: false,
        flutterTest: false,
        useFirebaseEmulator: true,
        starter: () => startCount += 1,
      );

      expect(startCount, 0);
    });

    test('通常環境ではSDK追跡を1回開始する', () {
      var startCount = 0;

      startAirbridgeTrackingIfAllowed(
        testMode: false,
        flutterTest: false,
        useFirebaseEmulator: false,
        starter: () => startCount += 1,
      );

      expect(startCount, 1);
    });
  });
}

class _RecordedEvent {
  const _RecordedEvent({
    required this.category,
    required this.customAttributes,
  });

  final String category;
  final Map<String, dynamic> customAttributes;
}
