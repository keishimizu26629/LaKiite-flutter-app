import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/domain/interfaces/i_growth_analytics.dart';
import 'package:lakiite/domain/interfaces/i_user_repository.dart';

import '../../mock/analytics/recording_growth_analytics.dart';
import '../../mock/repository/mock_auth_repository.dart';

void main() {
  group('AuthNotifier signUp growth analytics', () {
    late MockAuthRepository authRepository;
    late _UserRepository userRepository;
    late RecordingGrowthAnalytics analytics;
    late ProviderContainer container;

    setUp(() {
      authRepository = MockAuthRepository();
      userRepository = _UserRepository();
      analytics = RecordingGrowthAnalytics();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          authStateStreamProvider.overrideWith(
            (ref) => Stream.value(AuthState.unauthenticated()),
          ),
          userRepositoryProvider.overrideWithValue(userRepository),
          growthAnalyticsProvider.overrideWithValue(analytics),
        ],
      );
    });

    tearDown(() {
      authRepository.dispose();
      container.dispose();
    });

    test('プロフィール保存成功後に sign_up_completed を1回記録する', () async {
      await container.read(authNotifierProvider.notifier).signUp(
            'new-user@example.com',
            'password123',
            'new-user',
          );

      expect(userRepository.updatedUser, isNotNull);
      expect(
        analytics.signUpAuthMethods,
        [GrowthAuthMethod.emailPassword],
      );
    });

    test('プロフィール保存に失敗した場合は記録しない', () async {
      userRepository.shouldFailUpdate = true;

      await expectLater(
        container.read(authNotifierProvider.notifier).signUp(
              'new-user@example.com',
              'password123',
              'new-user',
            ),
        throwsStateError,
      );

      expect(analytics.signUpAuthMethods, isEmpty);
    });
  });
}

class _UserRepository implements IUserRepository {
  UserModel? updatedUser;
  bool shouldFailUpdate = false;

  @override
  Future<void> updateUser(UserModel user) async {
    if (shouldFailUpdate) throw StateError('profile save failed');
    updatedUser = user;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
