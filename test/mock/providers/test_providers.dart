import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import 'package:lakiite/domain/service/service_provider.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/notification.dart';
import 'package:lakiite/domain/interfaces/i_auth_repository.dart';
import '../repository/mock_auth_repository.dart';
import '../repository/mock_schedule_repository.dart';
import '../repository/mock_list_repository.dart';
import '../repository/mock_notification_repository.dart';
import '../repository/mock_user_repository.dart';
import '../base_mock.dart';

// 認証リポジトリプロバイダー（presentation_providerに存在しない場合のため）
final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  throw UnimplementedError('テスト環境では直接使用せず、オーバーライドしてください');
});

class TestProviders {
  static MockAuthRepository? _mockAuthRepository;
  static MockScheduleRepository? _mockScheduleRepository;
  static MockListRepository? _mockListRepository;
  static MockNotificationRepository? _mockNotificationRepository;
  static MockUserRepository? _mockUserRepository;

  /// 基本的なモックプロバイダー
  static List<Override> get basic => [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
        scheduleRepositoryProvider.overrideWithValue(mockScheduleRepository),
        listRepositoryProvider.overrideWithValue(mockListRepository),
        notificationRepositoryProvider
            .overrideWithValue(mockNotificationRepository),
        userRepositoryProvider.overrideWithValue(mockUserRepository),
      ];

  /// 認証済み状態のモックプロバイダー
  static List<Override> get authenticated {
    final authRepo = mockAuthRepository;
    final userRepo = mockUserRepository;

    // テストユーザーを作成・設定
    final testUser = BaseMock.createTestUser();
    authRepo.setCurrentUser(testUser);
    userRepo.addTestUser(testUser);

    return basic;
  }

  /// 認証済み + 友達がいる状態のモックプロバイダー
  static List<Override> get authenticatedWithFriends {
    final authRepo = mockAuthRepository;
    final userRepo = mockUserRepository;

    // メインのテストユーザー
    final testUser = BaseMock.createTestUser();
    authRepo.setCurrentUser(testUser);
    userRepo.addTestUser(testUser);

    // 友達のテストユーザー
    final friend1 = BaseMock.createTestUser(
      id: 'friend-1',
      name: '友達1',
      displayName: '友達一郎',
    );
    final friend2 = BaseMock.createTestUser(
      id: 'friend-2',
      name: '友達2',
      displayName: '友達二郎',
    );

    userRepo.addTestUser(friend1);
    userRepo.addTestUser(friend2);
    userRepo.addFriendConnection(testUser.id, friend1.id);
    userRepo.addFriendConnection(testUser.id, friend2.id);

    return basic;
  }

  /// テスト失敗シナリオ用プロバイダー
  static List<Override> get withFailures {
    mockAuthRepository.setShouldFailLogin(true);
    mockScheduleRepository.setShouldFailSave(true);
    mockListRepository.setShouldFailCreate(true);
    mockNotificationRepository.setShouldFailCreate(true);
    mockUserRepository.setShouldFailGet(true);
    return basic;
  }

  /// ログインフォーム用のプロバイダー（未認証状態）
  static List<Override> get forLoginForm => basic;

  /// サインアップフォーム用のプロバイダー（未認証状態）
  static List<Override> get forSignupForm => basic;

  /// スケジュール作成用のプロバイダー（認証済み + サンプルデータ）
  static List<Override> get forScheduleCreation {
    final overrides = authenticated;

    // サンプルスケジュールの追加
    final sampleSchedule = BaseMock.createTestSchedule(
      title: '既存のサンプルスケジュール',
      description: 'テスト用の既存スケジュール',
    );
    mockScheduleRepository.addTestSchedule(sampleSchedule);

    return overrides;
  }

  /// リスト作成用のプロバイダー（認証済み + サンプルデータ）
  static List<Override> get forListCreation {
    final overrides = authenticatedWithFriends;

    // サンプルリストの追加
    final sampleList = UserList(
      id: 'sample-list-1',
      listName: '既存のサンプルリスト',
      ownerId: BaseMock.testUserId,
      memberIds: ['friend-1', 'friend-2'],
      description: 'テスト用の既存リスト',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    );
    mockListRepository.addTestList(sampleList);

    return overrides;
  }

  /// 友達申請用のプロバイダー（認証済み + 通知データ）
  static List<Override> get forFriendRequest {
    final overrides = authenticated;

    // 送信済み友達申請の通知
    final pendingRequest = Notification.createFriendRequest(
      fromUserId: BaseMock.testUserId,
      toUserId: 'potential-friend-1',
      fromUserDisplayName: BaseMock.testDisplayName,
    );
    mockNotificationRepository.addTestNotification(pendingRequest);

    // 受信した友達申請の通知
    final receivedRequest = Notification.createFriendRequest(
      fromUserId: 'potential-friend-2',
      toUserId: BaseMock.testUserId,
      fromUserDisplayName: '申請者',
    );
    mockNotificationRepository.addTestNotification(receivedRequest);

    return overrides;
  }

  // シングルトンパターンでモックインスタンスを管理
  static MockAuthRepository get mockAuthRepository {
    return _mockAuthRepository ??= MockAuthRepository();
  }

  static MockScheduleRepository get mockScheduleRepository {
    return _mockScheduleRepository ??= MockScheduleRepository();
  }

  static MockListRepository get mockListRepository {
    return _mockListRepository ??= MockListRepository();
  }

  static MockNotificationRepository get mockNotificationRepository {
    return _mockNotificationRepository ??= MockNotificationRepository();
  }

  static MockUserRepository get mockUserRepository {
    return _mockUserRepository ??= MockUserRepository();
  }

  /// テスト間でのリセット
  static void reset() {
    _mockAuthRepository?.reset();
    _mockScheduleRepository?.reset();
    _mockListRepository?.reset();
    _mockNotificationRepository?.reset();
    _mockUserRepository?.reset();

    _mockAuthRepository = null;
    _mockScheduleRepository = null;
    _mockListRepository = null;
    _mockNotificationRepository = null;
    _mockUserRepository = null;
  }
}
