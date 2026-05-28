import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/notification/notification_notifier.dart'
    as notification_app;
import 'package:lakiite/domain/entity/notification.dart';
import 'package:lakiite/domain/entity/schedule.dart';
import 'package:lakiite/domain/interfaces/i_schedule_repository.dart';
import 'package:lakiite/domain/interfaces/i_user_repository.dart';
import 'package:lakiite/infrastructure/firebase/push_notification_sender.dart';

import '../mock/repository/mock_notification_repository.dart';

class _FakeFirebaseUser implements firebase_auth.User {
  _FakeFirebaseUser(this._uid);

  final String _uid;

  @override
  String get uid => _uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFirebaseAuth implements firebase_auth.FirebaseAuth {
  final _controller = StreamController<firebase_auth.User?>.broadcast();
  firebase_auth.User? _currentUser;

  @override
  firebase_auth.User? get currentUser => _currentUser;

  void setCurrentUser(firebase_auth.User? user) {
    _currentUser = user;
    _controller.add(user);
  }

  @override
  Stream<firebase_auth.User?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  void dispose() {
    _controller.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TrackingUserRepository implements IUserRepository {
  _TrackingUserRepository(this.instanceId);

  final int instanceId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TrackingScheduleRepository implements IScheduleRepository {
  _TrackingScheduleRepository(this.instanceId);

  final int instanceId;

  @override
  Stream<List<Schedule>> watchUserSchedules(String userId) =>
      const Stream.empty();

  @override
  Stream<List<Schedule>> watchUserSchedulesForMonth(
    String userId,
    DateTime displayMonth,
  ) =>
      const Stream.empty();

  @override
  Stream<List<Schedule>> watchListSchedules(String listId) =>
      const Stream.empty();

  @override
  Stream<Schedule?> watchSchedule(String scheduleId) => const Stream.empty();

  @override
  Future<Schedule> createSchedule(Schedule schedule) =>
      Future.error(UnimplementedError());

  @override
  Future<void> deleteSchedule(String scheduleId) =>
      Future.error(UnimplementedError());

  @override
  Future<List<Schedule>> getListSchedules(String listId) =>
      Future.error(UnimplementedError());

  @override
  Future<List<Schedule>> getUserSchedules(String userId) =>
      Future.error(UnimplementedError());

  @override
  Future<void> updateSchedule(Schedule schedule) =>
      Future.error(UnimplementedError());
}

void main() {
  group('repository session scope', () {
    late ProviderContainer container;
    late _FakeFirebaseAuth firebaseAuth;
    late MockNotificationRepository notificationRepository;
    late ProviderSubscription<IUserRepository> userRepositorySubscription;
    late ProviderSubscription<IScheduleRepository>
        scheduleRepositorySubscription;
    var userRepositoryInstanceCount = 0;
    var scheduleRepositoryInstanceCount = 0;

    setUp(() {
      firebaseAuth = _FakeFirebaseAuth();
      notificationRepository = MockNotificationRepository();

      container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(firebaseAuth),
          userRepositoryFactoryProvider.overrideWithValue(
            () => _TrackingUserRepository(++userRepositoryInstanceCount),
          ),
          scheduleRepositoryFactoryProvider.overrideWithValue(
            () =>
                _TrackingScheduleRepository(++scheduleRepositoryInstanceCount),
          ),
          notification_app.notificationRepositoryProvider
              .overrideWithValue(notificationRepository),
          notification_app.pushNotificationSenderProvider.overrideWithValue(
            PushNotificationSender(
              cloudFunctionUrl: 'https://example.test/push',
              tokenResolver: (_) async => const [],
            ),
          ),
        ],
      );

      userRepositorySubscription = container.listen(
        userRepositoryProvider,
        (_, __) {},
        fireImmediately: true,
      );
      scheduleRepositorySubscription = container.listen(
        scheduleRepositoryProvider,
        (_, __) {},
        fireImmediately: true,
      );
    });

    tearDown(() {
      userRepositorySubscription.close();
      scheduleRepositorySubscription.close();
      firebaseAuth.dispose();
      container.dispose();
    });

    test('ログアウト時に repository インスタンスを作り直す', () async {
      firebaseAuth.setCurrentUser(_FakeFirebaseUser('user-a'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final signedInUserRepository =
          container.read(userRepositoryProvider) as _TrackingUserRepository;
      final signedInScheduleRepository = container
          .read(scheduleRepositoryProvider) as _TrackingScheduleRepository;

      firebaseAuth.setCurrentUser(null);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final signedOutUserRepository =
          container.read(userRepositoryProvider) as _TrackingUserRepository;
      final signedOutScheduleRepository = container
          .read(scheduleRepositoryProvider) as _TrackingScheduleRepository;

      expect(
        signedOutUserRepository.instanceId,
        isNot(signedInUserRepository.instanceId),
      );
      expect(
        signedOutScheduleRepository.instanceId,
        isNot(signedInScheduleRepository.instanceId),
      );
    });

    test('ユーザー切替時に repository インスタンスを作り直す', () async {
      firebaseAuth.setCurrentUser(_FakeFirebaseUser('user-a'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final userARepository =
          container.read(userRepositoryProvider) as _TrackingUserRepository;
      final scheduleUserARepository = container.read(scheduleRepositoryProvider)
          as _TrackingScheduleRepository;

      firebaseAuth.setCurrentUser(_FakeFirebaseUser('user-b'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final userBRepository =
          container.read(userRepositoryProvider) as _TrackingUserRepository;
      final scheduleUserBRepository = container.read(scheduleRepositoryProvider)
          as _TrackingScheduleRepository;

      expect(userBRepository.instanceId, isNot(userARepository.instanceId));
      expect(
        scheduleUserBRepository.instanceId,
        isNot(scheduleUserARepository.instanceId),
      );
    });

    test('フレンド申請承認では user repository を作り直さない', () async {
      firebaseAuth.setCurrentUser(_FakeFirebaseUser('receiver-id'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      notificationRepository.addTestNotification(
        Notification(
          id: 'friend-request-id',
          type: NotificationType.friend,
          sendUserId: 'sender-id',
          receiveUserId: 'receiver-id',
          sendUserDisplayName: '申請者',
          receiveUserDisplayName: '受信者',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          status: NotificationStatus.pending,
        ),
      );

      final before =
          container.read(userRepositoryProvider) as _TrackingUserRepository;

      await container
          .read(notification_app.notificationNotifierProvider.notifier)
          .acceptNotification('friend-request-id');

      final after =
          container.read(userRepositoryProvider) as _TrackingUserRepository;

      expect(after.instanceId, before.instanceId);
    });
  });
}
