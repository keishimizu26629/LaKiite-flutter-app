import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/domain/interfaces/i_friend_list_repository.dart';
import 'package:lakiite/domain/interfaces/i_display_list_repository.dart';
import 'package:lakiite/domain/interfaces/i_list_repository.dart';
import 'package:lakiite/domain/interfaces/i_notification_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_access_grant_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_repository.dart';
import 'package:lakiite/domain/interfaces/i_user_repository.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/repository/reaction_repository.dart';
import 'package:lakiite/domain/service/list_manager.dart';
import 'package:lakiite/domain/service/schedule_manager.dart';
import 'package:lakiite/domain/service/user_manager.dart';
import 'package:lakiite/infrastructure/friend_list_repository.dart';
import 'package:lakiite/infrastructure/display_list_repository.dart';
import 'package:lakiite/infrastructure/encryption/schedule_encryption_service.dart';
import 'package:lakiite/infrastructure/list_repository.dart';
import 'package:lakiite/infrastructure/notification_repository.dart';
import 'package:lakiite/infrastructure/repository/reaction_repository_impl.dart';
import 'package:lakiite/infrastructure/schedule_interaction_repository.dart';
import 'package:lakiite/infrastructure/schedule_repository.dart';
import 'package:lakiite/infrastructure/user_repository.dart';

typedef UserRepositoryFactory = IUserRepository Function();
typedef ScheduleRepositoryFactory = IScheduleRepository Function();

/// Firebase認証インスタンスを提供するプロバイダー。
final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);

final scheduleEncryptionServiceProvider =
    Provider<ScheduleEncryptionService>((ref) {
  return ScheduleEncryptionService();
});

final schedulePrivateKeyBackupExistsProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, uid) {
  final encryptionService = ref.watch(scheduleEncryptionServiceProvider);
  return encryptionService.hasPrivateKeyBackup(uid);
});

/// Firebase 認証状態の変化を監視し、repository のセッション境界を提供する。
final repositorySessionKeyProvider = StreamProvider.autoDispose<String?>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return firebaseAuth.authStateChanges().map((user) => user?.uid);
});

/// ユーザーリポジトリを作成するfactory。
final userRepositoryFactoryProvider = Provider<UserRepositoryFactory>((ref) {
  return () => UserRepository();
});

/// スケジュールリポジトリを作成するfactory。
final scheduleRepositoryFactoryProvider =
    Provider<ScheduleRepositoryFactory>((ref) {
  return () => ScheduleRepository();
});

/// ユーザーリポジトリプロバイダー。
final userRepositoryProvider = Provider<IUserRepository>((ref) {
  ref.watch(repositorySessionKeyProvider);

  final repository = ref.watch(userRepositoryFactoryProvider).call();
  ref.onDispose(() {
    if (repository is UserRepository) {
      repository.clearCache();
    }
  });
  return repository;
});

/// リストリポジトリプロバイダー。
final listRepositoryProvider = Provider<IListRepository>((ref) {
  return ListRepository();
});

/// 表示用リストリポジトリプロバイダー。
final displayListRepositoryProvider = Provider<IDisplayListRepository>((ref) {
  return DisplayListRepository();
});

/// スケジュールリポジトリプロバイダー。
final scheduleRepositoryProvider = Provider<IScheduleRepository>((ref) {
  ref.watch(repositorySessionKeyProvider);
  return ref.watch(scheduleRepositoryFactoryProvider).call();
});

/// 通知リポジトリプロバイダー。
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return NotificationRepository();
});

/// フレンドリストリポジトリプロバイダー。
final friendListRepositoryProvider = Provider<IFriendListRepository>((ref) {
  return FriendListRepository();
});

/// スケジュールインタラクションリポジトリプロバイダー。
final scheduleInteractionRepositoryProvider =
    Provider<IScheduleInteractionRepository>((ref) {
  return ScheduleInteractionRepository();
});

/// リアクションリポジトリプロバイダー。
final reactionRepositoryProvider = Provider<ReactionRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  return ReactionRepositoryImpl(firestore);
});

/// リスト管理サービスのプロバイダー。
final listManagerProvider = Provider<IListManager>((ref) {
  return ListManager(
    ref.watch(listRepositoryProvider),
    scheduleAccessGrantRepository: _LazyScheduleAccessGrantRepository(ref),
  );
});

class _LazyScheduleAccessGrantRepository
    implements IScheduleAccessGrantRepository {
  _LazyScheduleAccessGrantRepository(this._ref);

  final Ref _ref;

  @override
  Future<void> grantListSchedulesAccessToUser({
    required String listId,
    required String userId,
  }) async {
    final scheduleRepository = _ref.read(scheduleRepositoryProvider);
    if (scheduleRepository is! IScheduleAccessGrantRepository) {
      return;
    }

    final scheduleAccessGrantRepository =
        scheduleRepository as IScheduleAccessGrantRepository;
    await scheduleAccessGrantRepository.grantListSchedulesAccessToUser(
      listId: listId,
      userId: userId,
    );
  }

  @override
  Future<void> syncListSchedulesAccess({
    required UserList beforeList,
    required UserList afterList,
  }) async {
    final scheduleRepository = _ref.read(scheduleRepositoryProvider);
    if (scheduleRepository is! IScheduleAccessGrantRepository) {
      return;
    }

    final scheduleAccessGrantRepository =
        scheduleRepository as IScheduleAccessGrantRepository;
    await scheduleAccessGrantRepository.syncListSchedulesAccess(
      beforeList: beforeList,
      afterList: afterList,
    );
  }
}

/// ユーザー管理サービスのプロバイダー。
final userManagerProvider = Provider<IUserManager>((ref) {
  return UserManager(
    ref.watch(userRepositoryProvider),
  );
});

/// スケジュール管理サービスのプロバイダー。
final scheduleManagerProvider = Provider<IScheduleManager>((ref) {
  return ScheduleManager(
    ref.watch(scheduleRepositoryProvider),
    ref.watch(userRepositoryProvider),
    ref.watch(scheduleInteractionRepositoryProvider),
  );
});
