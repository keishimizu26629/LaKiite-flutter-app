import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/app/di/providers.dart' as di;
import 'package:lakiite/application/auth/auth_notifier.dart' as auth_app;
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/notification/notification_notifier.dart'
    as notification_app;
import 'package:lakiite/application/schedule/schedule_notifier.dart';
import 'package:lakiite/domain/entity/notification.dart';
import 'package:lakiite/domain/entity/schedule_comment.dart';
import 'package:lakiite/domain/entity/schedule_reaction.dart';
import 'package:lakiite/domain/interfaces/i_friend_list_repository.dart';
import 'package:lakiite/domain/interfaces/i_image_processor_service.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';
import 'package:lakiite/domain/interfaces/i_storage_service.dart';
import 'package:lakiite/infrastructure/firebase/push_notification_sender.dart';
import 'package:lakiite/infrastructure/providers.dart';
import 'package:lakiite/presentation/my_page/my_page_view_model.dart';

import '../../mock/base_mock.dart';
import '../../mock/repository/mock_auth_repository.dart';
import '../../mock/repository/mock_notification_repository.dart';
import '../../mock/repository/mock_schedule_repository.dart';
import '../../mock/repository/mock_user_repository.dart';

void main() {
  group('Primary user flows', () {
    late MockAuthRepository authRepository;
    late MockUserRepository userRepository;
    late MockScheduleRepository scheduleRepository;
    late MockNotificationRepository notificationRepository;
    late _FakeFriendListRepository friendListRepository;
    late _FakeScheduleInteractionRepository scheduleInteractionRepository;
    late _FakeStorageService storageService;
    late _FakeImageProcessorService imageProcessorService;
    late ProviderContainer container;

    setUp(() {
      authRepository = MockAuthRepository();
      userRepository = MockUserRepository();
      scheduleRepository = MockScheduleRepository();
      notificationRepository = MockNotificationRepository();
      friendListRepository = _FakeFriendListRepository();
      scheduleInteractionRepository = _FakeScheduleInteractionRepository();
      storageService = _FakeStorageService();
      imageProcessorService = _FakeImageProcessorService();

      container = ProviderContainer(
        overrides: [
          auth_app.authRepositoryProvider.overrideWithValue(authRepository),
          auth_app.authStateStreamProvider.overrideWith((ref) {
            return authRepository.authStateChanges().map((user) {
              if (user == null) {
                return AuthState.unauthenticated();
              }
              return AuthState.authenticated(user);
            });
          }),
          di.userRepositoryProvider.overrideWithValue(userRepository),
          di.scheduleRepositoryProvider.overrideWithValue(scheduleRepository),
          di.friendListRepositoryProvider
              .overrideWithValue(friendListRepository),
          di.scheduleInteractionRepositoryProvider
              .overrideWithValue(scheduleInteractionRepository),
          notification_app.notificationRepositoryProvider
              .overrideWithValue(notificationRepository),
          notification_app.pushNotificationSenderProvider.overrideWithValue(
            PushNotificationSender(
              cloudFunctionUrl: 'https://example.test/push',
              tokenResolver: (_) async => const [],
            ),
          ),
          storageServiceProvider.overrideWithValue(storageService),
          imageProcessorServiceProvider
              .overrideWithValue(imageProcessorService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      authRepository.dispose();
    });

    test('ログインすると認証済み状態になる', () async {
      AsyncValue<AuthState>? latestState;
      final subscription = container.listen(
        auth_app.authNotifierProvider,
        (_, next) => latestState = next,
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await container
          .read(auth_app.authNotifierProvider.notifier)
          .signIn(BaseMock.testEmail, 'password123');

      final state = latestState;

      expect(state?.hasValue, isTrue);
      expect(state?.requireValue.isAuthenticated, isTrue);
      expect(state?.requireValue.user?.id, BaseMock.testUserId);
    });

    test('新規作成すると表示名がユーザー情報へ反映される', () async {
      userRepository.addTestUser(BaseMock.createTestUser());

      await container.read(auth_app.authNotifierProvider.notifier).signUp(
            'new-user@example.com',
            'password123',
            '登録名',
            displayName: '表示名',
          );

      final createdUser = await userRepository.getUser(BaseMock.testUserId);

      expect(createdUser?.name, '登録名');
      expect(createdUser?.displayName, '表示名');
    });

    test('友達申請を作成できる', () async {
      await container
          .read(notification_app.notificationNotifierProvider.notifier)
          .createFriendRequest(
            fromUserId: 'sender-id',
            toUserId: 'receiver-id',
            fromUserDisplayName: '申請者',
            toUserDisplayName: '受信者',
          );

      final sent = await notificationRepository
          .watchSentNotifications('sender-id')
          .first;

      expect(sent, hasLength(1));
      expect(sent.single.type, NotificationType.friend);
      expect(sent.single.status, NotificationStatus.pending);
    });

    test('友達申請を承認すると通知と双方の友達リストが更新される', () async {
      final sender = BaseMock.createTestUser(
        id: 'sender-id',
        name: '申請者',
        displayName: '申請者',
      );
      final receiver = BaseMock.createTestUser(
        id: 'receiver-id',
        name: '受信者',
        displayName: '受信者',
      );
      userRepository
        ..addTestUser(sender)
        ..addTestUser(receiver);
      notificationRepository.addTestNotification(
        Notification(
          id: 'friend-request-id',
          type: NotificationType.friend,
          sendUserId: sender.id,
          receiveUserId: receiver.id,
          sendUserDisplayName: sender.displayName,
          receiveUserDisplayName: receiver.displayName,
          status: NotificationStatus.pending,
          createdAt: DateTime(2026, 5, 22),
          updatedAt: DateTime(2026, 5, 22),
        ),
      );

      await container
          .read(notification_app.notificationNotifierProvider.notifier)
          .acceptNotification('friend-request-id');

      final accepted =
          await notificationRepository.getNotification('friend-request-id');
      final updatedSender = await userRepository.getUser(sender.id);
      final updatedReceiver = await userRepository.getUser(receiver.id);

      expect(accepted?.status, NotificationStatus.accepted);
      expect(accepted?.isRead, isTrue);
      expect(updatedSender?.friends, contains(receiver.id));
      expect(updatedReceiver?.friends, contains(sender.id));
    });

    test('申請元ユーザーが削除済みの友達申請を承認すると通知を期限切れとして既読にする', () async {
      final receiver = BaseMock.createTestUser(
        id: 'receiver-id',
        name: '受信者',
        displayName: '受信者',
      );
      userRepository.addTestUser(receiver);
      notificationRepository.addTestNotification(
        Notification(
          id: 'deleted-sender-request-id',
          type: NotificationType.friend,
          sendUserId: 'deleted-sender-id',
          receiveUserId: receiver.id,
          sendUserDisplayName: '削除済み申請者',
          receiveUserDisplayName: receiver.displayName,
          status: NotificationStatus.pending,
          createdAt: DateTime(2026, 5, 22),
          updatedAt: DateTime(2026, 5, 22),
        ),
      );

      await container
          .read(notification_app.notificationNotifierProvider.notifier)
          .acceptNotification('deleted-sender-request-id');

      final expired = await notificationRepository
          .getNotification('deleted-sender-request-id');
      final updatedReceiver = await userRepository.getUser(receiver.id);

      expect(expired?.status, NotificationStatus.expired);
      expect(expired?.isRead, isTrue);
      expect(updatedReceiver?.friends, isNot(contains('deleted-sender-id')));
    });

    test('予定を追加すると保存済み予定として取得できる', () async {
      final owner = BaseMock.createTestUser();
      authRepository.setCurrentUser(owner);
      userRepository.addTestUser(owner);

      final start = DateTime(2026, 6, 1, 10);
      await container.read(scheduleNotifierProvider.notifier).createSchedule(
        title: 'ランチ',
        description: '友達とランチ',
        location: '渋谷',
        startDateTime: start,
        endDateTime: start.add(const Duration(hours: 1)),
        ownerId: owner.id,
        sharedLists: const [],
        visibleTo: const [],
      );

      final schedules = await scheduleRepository.getUserSchedules(owner.id);

      expect(schedules, hasLength(1));
      expect(schedules.single.title, 'ランチ');
      expect(schedules.single.ownerDisplayName, owner.displayName);
    });

    test('プロフィール画像を変更するとStorage URLがユーザー情報へ反映される', () async {
      final user = BaseMock.createTestUser();
      userRepository.addTestUser(user);
      final imageFile = File(
        '${Directory.systemTemp.path}/lakiite-profile-flow-test.jpg',
      );
      await imageFile.writeAsBytes([1, 2, 3]);

      final viewModel = container.read(myPageViewModelProvider.notifier);
      await viewModel.loadUser(user.id);

      await viewModel.updateProfile(
        name: user.name,
        displayName: user.displayName,
        searchIdStr: user.searchId.toString(),
        imageFile: imageFile,
      );

      final updatedUser = await userRepository.getUser(user.id);

      expect(updatedUser?.iconUrl, storageService.uploadedUrl);
      expect(storageService.uploadedPath, 'v1/users/icon/${user.id}');
    });
  });
}

class _FakeFriendListRepository implements IFriendListRepository {
  final Map<String, List<String>> membersByListId = {};

  @override
  Future<List<String>?> getListMemberIds(String listId) async {
    return membersByListId[listId];
  }
}

class _FakeScheduleInteractionRepository
    implements IScheduleInteractionRepository {
  @override
  Future<String> addComment(
    String scheduleId,
    String userId,
    String content,
  ) async {
    return 'comment-id';
  }

  @override
  Future<String> addReaction(
    String scheduleId,
    String userId,
    ReactionType type,
  ) async {
    return 'reaction-id';
  }

  @override
  Future<void> deleteComment(String scheduleId, String commentId) async {}

  @override
  Future<int> getCommentCount(String scheduleId) async {
    return 0;
  }

  @override
  Future<List<ScheduleComment>> getComments(String scheduleId) async {
    return const [];
  }

  @override
  Future<int> getReactionCount(String scheduleId) async {
    return 0;
  }

  @override
  Future<List<ScheduleReaction>> getReactions(String scheduleId) async {
    return const [];
  }

  @override
  Future<void> removeReaction(String scheduleId, String userId) async {}

  @override
  Future<void> updateComment(
    String scheduleId,
    String commentId,
    String content,
  ) async {}

  @override
  Stream<List<ScheduleComment>> watchComments(String scheduleId) {
    return const Stream.empty();
  }

  @override
  Stream<List<ScheduleReaction>> watchReactions(String scheduleId) {
    return const Stream.empty();
  }
}

class _FakeStorageService implements IStorageService {
  final uploadedUrl = 'https://storage.example.test/profile.jpg';
  String? uploadedPath;

  @override
  Future<String> uploadFile({
    required String path,
    required File file,
    required Map<String, String> metadata,
    String contentType = 'image/jpeg',
  }) async {
    uploadedPath = path;
    return uploadedUrl;
  }
}

class _FakeImageProcessorService implements IImageProcessorService {
  @override
  Future<File> compressImage(
    File imageFile, {
    int minWidth = 300,
    int minHeight = 300,
    int quality = 85,
  }) async {
    return imageFile;
  }

  @override
  Future<Directory> createTempDirectory() {
    return Directory.systemTemp.createTemp('lakiite-profile-flow-test');
  }

  @override
  Future<File> createTempFile(List<int> data, String extension) async {
    final directory = await createTempDirectory();
    final file = File('${directory.path}/image.$extension');
    return file.writeAsBytes(data);
  }
}
