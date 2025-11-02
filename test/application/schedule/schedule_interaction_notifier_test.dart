import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/auth/auth_notifier.dart' as auth;
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/notification/notification_notifier.dart'
    as notification;
import 'package:lakiite/application/schedule/schedule_interaction_notifier.dart';
import 'package:lakiite/config/app_config.dart';
import 'package:lakiite/domain/entity/notification.dart' as domain_notification;
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/interfaces/i_notification_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_repository.dart';
import 'package:lakiite/domain/interfaces/i_user_repository.dart';
import 'package:lakiite/domain/value/user_id.dart';
import 'package:lakiite/presentation/presentation_provider.dart';

class _StubAuthNotifier extends auth.AuthNotifier {
  _StubAuthNotifier(this._state);

  final AuthState _state;

  @override
  FutureOr<AuthState> build() => _state;
}

class _FakeScheduleRepository implements IScheduleRepository {
  _FakeScheduleRepository(this._schedule);

  final Schedule _schedule;

  @override
  Stream<Schedule?> watchSchedule(String scheduleId) =>
      Stream<Schedule?>.value(_schedule);

  // Unused interface members
  @override
  Future<void> deleteSchedule(String scheduleId) =>
      Future.error(UnimplementedError());

  @override
  Future<List<Schedule>> getListSchedules(String listId) =>
      Future.error(UnimplementedError());

  @override
  Future<Schedule> createSchedule(Schedule schedule) =>
      Future.error(UnimplementedError());

  @override
  Future<List<Schedule>> getUserSchedules(String userId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> updateSchedule(Schedule schedule) =>
      Future.error(UnimplementedError());

  @override
  Stream<List<Schedule>> watchListSchedules(String listId) =>
      Stream<List<Schedule>>.error(UnimplementedError());

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) =>
      Stream<List<Schedule>>.error(UnimplementedError());

  @override
  Stream<List<Schedule>> watchUserSchedulesForMonth(
          String userId, DateTime displayMonth) =>
      Stream<List<Schedule>>.error(UnimplementedError());
}

class _FakeUserRepository implements IUserRepository {
  _FakeUserRepository(this._user);

  final UserModel _user;

  @override
  Future<UserModel?> getUser(String id) async => id == _user.id ? _user : null;

  // All other methods are not used in this test.
  @override
  Future<void> addToList(String userId, String memberId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> createUser(UserModel user) => Future.error(UnimplementedError());

  @override
  Future<void> deleteUser(String id) => Future.error(UnimplementedError());

  @override
  Future<PublicUserModel?> getFriendPublicProfile(String id) =>
      Future.error(UnimplementedError());

  @override
  Future<List<PublicUserModel>> getPublicProfiles(List<String> userIds) =>
      Future.error(UnimplementedError());

  @override
  Future<SearchUserModel?> findBySearchId(String searchId) =>
      Future.error(UnimplementedError());

  @override
  Future<SearchUserModel?> findByUserId(UserId userId) =>
      Future.error(UnimplementedError());

  @override
  Future<bool> isUserIdUnique(UserId userId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> removeFromList(String userId, String memberId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> updateUser(UserModel user) => Future.error(UnimplementedError());

  @override
  Future<String?> uploadUserIcon(String userId, Uint8List imageBytes) =>
      Future.error(UnimplementedError());

  @override
  Future<void> deleteUserIcon(String userId) =>
      Future.error(UnimplementedError());

  @override
  Stream<PrivateUserModel?> watchPrivateProfile(String id) =>
      Stream<PrivateUserModel?>.error(UnimplementedError());

  @override
  Stream<PublicUserModel?> watchPublicProfile(String id) =>
      Stream<PublicUserModel?>.error(UnimplementedError());

  @override
  Stream<UserModel?> watchUser(String id) =>
      Stream<UserModel?>.error(UnimplementedError());
}

class _FakeNotificationRepository implements INotificationRepository {
  @override
  Future<void> createNotification(
      domain_notification.Notification notification) async {}

  @override
  Future<void> updateNotification(
          domain_notification.Notification notification) =>
      Future.error(UnimplementedError());

  @override
  Future<domain_notification.Notification?> getNotification(
          String notificationId) =>
      Future.error(UnimplementedError());

  @override
  Stream<List<domain_notification.Notification>> watchReceivedNotifications(
          String userId) =>
      const Stream.empty();

  @override
  Stream<List<domain_notification.Notification>>
      watchReceivedNotificationsByType(
              String userId, domain_notification.NotificationType type) =>
          const Stream.empty();

  @override
  Stream<List<domain_notification.Notification>> watchSentNotifications(
          String userId) =>
      const Stream.empty();

  @override
  Stream<List<domain_notification.Notification>> watchSentNotificationsByType(
          String userId, domain_notification.NotificationType type) =>
      const Stream.empty();

  @override
  Future<bool> hasPendingFriendRequest(
          String fromUserId, String toUserId) async =>
      false;

  @override
  Future<bool> hasPendingGroupInvitation(
          String fromUserId, String toUserId, String groupId) async =>
      false;

  @override
  Future<void> acceptNotification(String notificationId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> rejectNotification(String notificationId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> markAsRead(String notificationId) =>
      Future.error(UnimplementedError());

  @override
  Stream<int> watchUnreadCount(String userId) => const Stream.empty();

  @override
  Stream<int> watchUnreadCountByType(
          String userId, domain_notification.NotificationType type) =>
      const Stream.empty();
}

class _FakeNotificationNotifier extends notification.NotificationNotifier {
  _FakeNotificationNotifier(Ref ref)
      : super(_FakeNotificationRepository(), ref);

  @override
  Future<void> createReactionNotification({
    required String toUserId,
    required String fromUserId,
    required String scheduleId,
    required String interactionId,
    String? fromUserDisplayName,
  }) async {}

  @override
  Future<void> createCommentNotification({
    required String toUserId,
    required String fromUserId,
    required String scheduleId,
    required String interactionId,
    String? fromUserDisplayName,
  }) async {}
}

class _FakeScheduleInteractionRepository
    implements IScheduleInteractionRepository {
  _FakeScheduleInteractionRepository()
      : _reactionListener = Completer<void>(),
        _latestReactions = null,
        _commentsController =
            StreamController<List<ScheduleComment>>.broadcast() {
    _reactionsController =
        StreamController<List<ScheduleReaction>>.broadcast(onListen: () {
      if (!_reactionListener.isCompleted) {
        _reactionListener.complete();
      }
      final latest = _latestReactions;
      if (latest != null) {
        _reactionsController.add(latest);
      }
    });
    _commentsController.add(const <ScheduleComment>[]);
  }

  final Completer<void> _reactionListener;
  List<ScheduleReaction>? _latestReactions;

  late final StreamController<List<ScheduleReaction>> _reactionsController;
  final StreamController<List<ScheduleComment>> _commentsController;

  Completer<String>? addReactionCompleter;

  void emitReactions(List<ScheduleReaction> reactions) {
    _latestReactions = reactions;
    if (!_reactionsController.isClosed) {
      _reactionsController.add(reactions);
    }
  }

  Future<void> waitForReactionListener() => _reactionListener.future;

  void dispose() {
    _reactionsController.close();
    _commentsController.close();
  }

  @override
  Future<String> addReaction(
      String scheduleId, String userId, ReactionType type) {
    addReactionCompleter ??= Completer<String>();
    return addReactionCompleter!.future;
  }

  @override
  Future<void> removeReaction(String scheduleId, String userId) async {}

  @override
  Stream<List<ScheduleReaction>> watchReactions(String scheduleId) =>
      _reactionsController.stream;

  @override
  Stream<List<ScheduleComment>> watchComments(String scheduleId) =>
      _commentsController.stream;

  // Unused members
  @override
  Future<List<ScheduleReaction>> getReactions(String scheduleId) =>
      Future.error(UnimplementedError());

  @override
  Future<List<ScheduleComment>> getComments(String scheduleId) =>
      Future.error(UnimplementedError());

  @override
  Future<String> addComment(String scheduleId, String userId, String content) =>
      Future.error(UnimplementedError());

  @override
  Future<void> deleteComment(String scheduleId, String commentId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> updateComment(
          String scheduleId, String commentId, String content) =>
      Future.error(UnimplementedError());

  @override
  Future<int> getReactionCount(String scheduleId) async {
    return _latestReactions?.length ?? 0;
  }

  @override
  Future<int> getCommentCount(String scheduleId) async {
    return 0; // テスト用のダミー実装
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScheduleInteractionNotifier', () {
    setUpAll(() async {
      AppConfig.initialize(Environment.development);
    });

    test('toggleReaction should retain concurrent reactions from other users',
        () async {
      final user = UserModel(
        publicProfile: PublicUserModel(
          id: 'user-1',
          displayName: 'User One',
          searchId: UserId('USRTEST1'),
          iconUrl: null,
          shortBio: null,
        ),
        privateProfile: PrivateUserModel(
          id: 'user-1',
          name: 'User One',
          friends: const [],
          groups: const [],
          lists: const [],
          createdAt: DateTime(2024, 1, 1),
        ),
      );

      final schedule = Schedule(
        id: 'schedule-1',
        title: 'Sample',
        description: 'Desc',
        startDateTime: DateTime(2024, 1, 1, 10),
        endDateTime: DateTime(2024, 1, 1, 12),
        ownerId: user.id,
        ownerDisplayName: user.displayName,
        sharedLists: const [],
        visibleTo: const [],
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final repository = _FakeScheduleInteractionRepository();
      addTearDown(repository.dispose);

      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(
              () => _StubAuthNotifier(AuthState.authenticated(user))),
          scheduleInteractionRepositoryProvider.overrideWithValue(repository),
          scheduleInteractionNotifierProvider.overrideWith((ref, scheduleId) {
            return ScheduleInteractionNotifier(
              ref.watch(scheduleInteractionRepositoryProvider),
              scheduleId,
              ref,
              enablePushNotifications: false,
            );
          }),
          scheduleRepositoryProvider.overrideWithValue(
            _FakeScheduleRepository(schedule),
          ),
          userRepositoryProvider.overrideWithValue(
            _FakeUserRepository(user),
          ),
          notification.notificationRepositoryProvider
              .overrideWithValue(_FakeNotificationRepository()),
          notification.notificationNotifierProvider.overrideWith((ref) {
            return _FakeNotificationNotifier(ref);
          }),
        ],
      );
      addTearDown(container.dispose);

      final provider = scheduleInteractionNotifierProvider(schedule.id);

      // Ensure notifier is created and subscriptions are active.
      container.read(provider);
      await repository.waitForReactionListener();

      final existing = ScheduleReaction(
        id: 'reaction-1',
        userId: 'friend-1',
        type: ReactionType.going,
        createdAt: DateTime(2024, 1, 1),
        userDisplayName: 'Friend',
      );
      repository.emitReactions([existing]);
      await Future.microtask(() {});

      expect(
        container.read(provider).reactions.map((r) => r.id),
        ['reaction-1'],
      );

      final remote = ScheduleReaction(
        id: 'reaction-2',
        userId: 'friend-2',
        type: ReactionType.thinking,
        createdAt: DateTime(2024, 1, 1, 1),
        userDisplayName: 'Friend Two',
      );

      repository.addReactionCompleter = Completer<String>();

      final toggleFuture = container
          .read(provider.notifier)
          .toggleReaction(user.id, ReactionType.going);

      await Future.microtask(() {});

      repository.emitReactions([existing, remote]);
      await Future.microtask(() {});

      repository.addReactionCompleter!.complete('reaction-current-user');

      await toggleFuture;

      final finalState = container.read(provider);

      expect(finalState.reactions.length, 3);
      expect(
        finalState.reactions.map((r) => r.id),
        containsAll(['reaction-1', 'reaction-2', 'reaction-current-user']),
      );
    });
  });
}
