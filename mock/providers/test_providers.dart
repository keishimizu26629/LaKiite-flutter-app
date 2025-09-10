import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/presentation/presentation_provider.dart';
import '../repositories/mock_auth_repository.dart';
import '../repositories/mock_schedule_repository.dart';
import '../repositories/mock_user_repository.dart';

/// 統合テスト用のプロバイダー設定クラス
class TestProviders {
  static MockAuthRepository? _mockAuthRepository;
  static MockScheduleRepository? _mockScheduleRepository;
  static MockUserRepository? _mockUserRepository;

  /// モックリポジトリーの取得
  static MockAuthRepository get mockAuthRepository {
    _mockAuthRepository ??= MockAuthRepository();
    return _mockAuthRepository!;
  }

  static MockScheduleRepository get mockScheduleRepository {
    _mockScheduleRepository ??= MockScheduleRepository();
    return _mockScheduleRepository!;
  }

  static MockUserRepository get mockUserRepository {
    _mockUserRepository ??= MockUserRepository();
    return _mockUserRepository!;
  }

  /// プロバイダーをリセット
  static void reset() {
    _mockAuthRepository = null;
    _mockScheduleRepository = null;
    _mockUserRepository = null;
  }

  /// 新規登録フォーム用のプロバイダーオーバーライド
  static List<Override> get forSignupForm {
    // 未認証状態でスタート
    mockAuthRepository.setUser(null);
    return [
      authRepositoryProvider.overrideWithValue(mockAuthRepository),
      userRepositoryProvider.overrideWithValue(mockUserRepository),
    ];
  }

  /// ログインフォーム用のプロバイダーオーバーライド
  static List<Override> get forLoginForm {
    // 未認証状態でスタート
    mockAuthRepository.setUser(null);
    return [
      authRepositoryProvider.overrideWithValue(mockAuthRepository),
      userRepositoryProvider.overrideWithValue(mockUserRepository),
    ];
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

    return [
      authRepositoryProvider.overrideWithValue(mockAuthRepository),
      userRepositoryProvider.overrideWithValue(mockUserRepository),
    ];
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

    return [
      authRepositoryProvider.overrideWithValue(mockAuthRepository),
      userRepositoryProvider.overrideWithValue(mockUserRepository),
      scheduleRepositoryProvider.overrideWithValue(mockScheduleRepository),
    ];
  }
}
