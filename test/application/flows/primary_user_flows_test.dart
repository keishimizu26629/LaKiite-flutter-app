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
import 'package:lakiite/domain/interfaces/i_image_cropper_service.dart';
import 'package:lakiite/domain/interfaces/i_image_processor_service.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';
import 'package:lakiite/domain/interfaces/i_storage_service.dart';
import 'package:lakiite/infrastructure/image_picker_service.dart';
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
    late _FakeImageCropperService imageCropperService;
    late _FakeImagePickerService imagePickerService;
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
      imageCropperService = _FakeImageCropperService();
      imagePickerService = _FakeImagePickerService();

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
          imageCropperServiceProvider.overrideWithValue(imageCropperService),
          imagePickerServiceProvider.overrideWithValue(imagePickerService),
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

    test('友達申請を承認すると通知を承認済みにする', () async {
      notificationRepository.addTestNotification(
        Notification(
          id: 'friend-request-id',
          type: NotificationType.friend,
          sendUserId: 'sender-id',
          receiveUserId: 'receiver-id',
          sendUserDisplayName: '申請者',
          receiveUserDisplayName: '受信者',
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

      expect(accepted?.status, NotificationStatus.accepted);
      expect(accepted?.isRead, isTrue);
    });

    test('友達申請承認は削除済みユーザー判定をクライアントで行わない', () async {
      notificationRepository.addTestNotification(
        Notification(
          id: 'deleted-sender-request-id',
          type: NotificationType.friend,
          sendUserId: 'deleted-sender-id',
          receiveUserId: 'receiver-id',
          sendUserDisplayName: '削除済み申請者',
          receiveUserDisplayName: '受信者',
          status: NotificationStatus.pending,
          createdAt: DateTime(2026, 5, 22),
          updatedAt: DateTime(2026, 5, 22),
        ),
      );

      await container
          .read(notification_app.notificationNotifierProvider.notifier)
          .acceptNotification('deleted-sender-request-id');

      final accepted = await notificationRepository
          .getNotification('deleted-sender-request-id');

      expect(accepted?.status, NotificationStatus.accepted);
      expect(accepted?.isRead, isTrue);
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

    test('プロフィール画像を選択すると切り取り後の画像を選択状態に保存する', () async {
      final user = BaseMock.createTestUser();
      userRepository.addTestUser(user);
      final pickedImageFile = File(
        '${Directory.systemTemp.path}/lakiite-picked-profile-test.jpg',
      );
      final croppedImageFile = File(
        '${Directory.systemTemp.path}/lakiite-cropped-profile-test.jpg',
      );
      await pickedImageFile.writeAsBytes([1, 2, 3]);
      await croppedImageFile.writeAsBytes([4, 5, 6]);
      imagePickerService.pickedPath = pickedImageFile.path;
      imageCropperService.croppedFile = croppedImageFile;

      final viewModel = container.read(myPageViewModelProvider.notifier);
      await viewModel.loadUser(user.id);

      await viewModel.pickImage();

      expect(imageCropperService.sourceFile?.path, pickedImageFile.path);
      expect(imageCropperService.aspectRatioX, 1);
      expect(imageCropperService.aspectRatioY, 1);
      expect(
        imageProcessorService.compressedSourceFile?.path,
        croppedImageFile.path,
      );
      expect(
        container.read(selectedImageProvider)?.path,
        croppedImageFile.path,
      );
    });

    test('プロフィール画像の切り取りをキャンセルすると選択状態を変更しない', () async {
      final user = BaseMock.createTestUser();
      userRepository.addTestUser(user);
      final pickedImageFile = File(
        '${Directory.systemTemp.path}/lakiite-picked-profile-cancel-test.jpg',
      );
      final currentSelectedImageFile = File(
        '${Directory.systemTemp.path}/lakiite-current-profile-test.jpg',
      );
      await pickedImageFile.writeAsBytes([1, 2, 3]);
      await currentSelectedImageFile.writeAsBytes([7, 8, 9]);
      imagePickerService.pickedPath = pickedImageFile.path;
      imageCropperService.croppedFile = null;
      container.read(selectedImageProvider.notifier).state =
          currentSelectedImageFile;

      final viewModel = container.read(myPageViewModelProvider.notifier);
      await viewModel.loadUser(user.id);

      await viewModel.pickImage();

      expect(imageCropperService.sourceFile?.path, pickedImageFile.path);
      expect(imageProcessorService.compressedSourceFile, isNull);
      expect(
        container.read(selectedImageProvider)?.path,
        currentSelectedImageFile.path,
      );
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
  File? compressedSourceFile;

  @override
  Future<File> compressImage(
    File imageFile, {
    int minWidth = 300,
    int minHeight = 300,
    int quality = 85,
  }) async {
    compressedSourceFile = imageFile;
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

class _FakeImageCropperService implements IImageCropperService {
  File? croppedFile;
  File? sourceFile;
  double? aspectRatioX;
  double? aspectRatioY;

  @override
  Future<File?> cropImage({
    required File sourceFile,
    double? aspectRatioX,
    double? aspectRatioY,
  }) async {
    this.sourceFile = sourceFile;
    this.aspectRatioX = aspectRatioX;
    this.aspectRatioY = aspectRatioY;
    return croppedFile;
  }
}

class _FakeImagePickerService extends ImagePickerService {
  String? pickedPath;

  @override
  Future<String?> pickImage(ImageSource imageSource) async {
    return pickedPath;
  }
}
