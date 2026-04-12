import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/application/notification/notification_notifier.dart'
    as notification;
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/infrastructure/providers.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import '../repositories/mock_auth_repository.dart';
import '../repositories/mock_list_repository.dart';
import '../repositories/mock_notification_repository.dart';
import '../repositories/mock_schedule_repository.dart';
import '../repositories/mock_user_repository.dart';
import '../services/mock_image_processor_service.dart';
import '../services/mock_storage_service.dart';

/// 統合テスト用のプロバイダー設定クラス
class TestProviders {
  static MockAuthRepository? _mockAuthRepository;
  static MockListRepository? _mockListRepository;
  static MockNotificationRepository? _mockNotificationRepository;
  static MockScheduleRepository? _mockScheduleRepository;
  static MockUserRepository? _mockUserRepository;
  static MockStorageService? _mockStorageService;
  static MockImageProcessorService? _mockImageProcessorService;

  /// モックリポジトリーの取得
  static MockAuthRepository get mockAuthRepository {
    _mockAuthRepository ??= MockAuthRepository();
    return _mockAuthRepository!;
  }

  static MockScheduleRepository get mockScheduleRepository {
    _mockScheduleRepository ??= MockScheduleRepository();
    return _mockScheduleRepository!;
  }

  static MockListRepository get mockListRepository {
    _mockListRepository ??= MockListRepository();
    return _mockListRepository!;
  }

  static MockNotificationRepository get mockNotificationRepository {
    _mockNotificationRepository ??= MockNotificationRepository();
    return _mockNotificationRepository!;
  }

  static MockUserRepository get mockUserRepository {
    _mockUserRepository ??= MockUserRepository();
    return _mockUserRepository!;
  }

  static MockStorageService get mockStorageService {
    _mockStorageService ??= MockStorageService();
    return _mockStorageService!;
  }

  static MockImageProcessorService get mockImageProcessorService {
    _mockImageProcessorService ??= MockImageProcessorService();
    return _mockImageProcessorService!;
  }

  static List<Override> _baseOverrides({String? currentUserId}) {
    return [
      authRepositoryProvider.overrideWithValue(mockAuthRepository),
      userRepositoryProvider.overrideWithValue(mockUserRepository),
      scheduleRepositoryProvider.overrideWithValue(mockScheduleRepository),
      listRepositoryProvider.overrideWithValue(mockListRepository),
      notification.notificationRepositoryProvider
          .overrideWithValue(mockNotificationRepository),
      storageServiceProvider.overrideWithValue(mockStorageService),
      imageProcessorServiceProvider
          .overrideWithValue(mockImageProcessorService),
      if (currentUserId != null)
        notification.currentUserIdProvider.overrideWithValue(currentUserId),
    ];
  }

  /// プロバイダーをリセット
  static void reset() {
    _mockAuthRepository = null;
    _mockListRepository = null;
    _mockNotificationRepository = null;
    _mockScheduleRepository = null;
    _mockUserRepository = null;
    _mockStorageService = null;
    _mockImageProcessorService = null;
  }

  /// 新規登録フォーム用のプロバイダーオーバーライド
  static List<Override> get forSignupForm {
    // 未認証状態でスタート
    mockAuthRepository.setUser(null);
    return _baseOverrides();
  }

  /// ログインフォーム用のプロバイダーオーバーライド
  static List<Override> get forLoginForm {
    // 未認証状態でスタート
    mockAuthRepository.setUser(null);
    return _baseOverrides();
  }

  /// 認証済み状態用のプロバイダーオーバーライド
  static List<Override> get authenticated {
    // モックユーザーを作成
    final testUser = UserModel.create(
      id: 'test-user-id',
      name: 'テストユーザー',
      displayName: 'テストニックネーム',
    );

    // 認証状態を初期化
    mockAuthRepository.setUser(testUser);
    mockUserRepository.addTestUser(testUser);

    return _baseOverrides(currentUserId: testUser.id);
  }

  /// スケジュール作成用のプロバイダーオーバーライド
  static List<Override> get forScheduleCreation {
    // モックユーザーを作成
    final testUser = UserModel.create(
      id: 'test-user-id',
      name: 'テストユーザー',
      displayName: 'テストニックネーム',
    );

    mockAuthRepository.setUser(testUser);
    mockUserRepository.addTestUser(testUser);
    mockScheduleRepository.setupSampleSchedules();

    return _baseOverrides(currentUserId: testUser.id);
  }
}
