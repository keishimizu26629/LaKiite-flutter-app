import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/group/group_notifier.dart';
import 'package:lakiite/application/group/group_state.dart';
import 'package:lakiite/application/list/list_notifier.dart';
import 'package:lakiite/application/list/list_state.dart';
import 'package:lakiite/application/schedule/schedule_notifier.dart';
import 'package:lakiite/application/schedule/schedule_state.dart';
import 'package:lakiite/domain/interfaces/i_group_repository.dart';
import 'package:lakiite/domain/interfaces/i_list_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_repository.dart';
import 'package:lakiite/domain/interfaces/i_notification_repository.dart';
import 'package:lakiite/domain/interfaces/i_user_repository.dart';
import 'package:lakiite/domain/interfaces/i_friend_list_repository.dart';
import 'package:lakiite/domain/interfaces/i_schedule_interaction_repository.dart';
import 'package:lakiite/infrastructure/schedule_interaction_repository.dart';
import 'package:lakiite/domain/service/service_provider.dart';
import 'package:lakiite/infrastructure/group_repository.dart';
import 'package:lakiite/infrastructure/list_repository.dart';
import 'package:lakiite/infrastructure/schedule_repository.dart';
import 'package:lakiite/infrastructure/notification_repository.dart';
import 'package:lakiite/infrastructure/user_repository.dart';
import 'package:lakiite/domain/entity/group.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/user.dart';
import 'package:lakiite/infrastructure/friend_list_repository.dart';
import '../domain/entity/schedule.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/domain/repository/reaction_repository.dart';
import 'package:lakiite/infrastructure/repository/reaction_repository_impl.dart';

export 'package:lakiite/application/notification/notification_notifier.dart'
    show currentUserIdProvider;
export 'package:lakiite/application/auth/auth_notifier.dart'
    show authNotifierProvider, authRepositoryProvider;

typedef UserRepositoryFactory = IUserRepository Function();
typedef ScheduleRepositoryFactory = IScheduleRepository Function();

/// Firebase認証インスタンスを提供するプロバイダー
final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);

/// Firebase 認証状態の変化を監視し、repository のセッション境界を提供する。
final repositorySessionKeyProvider = StreamProvider.autoDispose<String?>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return firebaseAuth.authStateChanges().map((user) => user?.uid);
});

/// リポジトリプロバイダー群
final userRepositoryFactoryProvider = Provider<UserRepositoryFactory>((ref) {
  return () => UserRepository();
});

final scheduleRepositoryFactoryProvider =
    Provider<ScheduleRepositoryFactory>((ref) {
  return () => ScheduleRepository();
});

// ユーザーリポジトリプロバイダー
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

/// グループリポジトリプロバイダー
final groupRepositoryProvider = Provider<IGroupRepository>((ref) {
  return GroupRepository();
});

/// リストリポジトリプロバイダー
final listRepositoryProvider = Provider<IListRepository>((ref) {
  return ListRepository();
});

/// スケジュールリポジトリプロバイダー
final scheduleRepositoryProvider = Provider<IScheduleRepository>((ref) {
  ref.watch(repositorySessionKeyProvider);
  return ref.watch(scheduleRepositoryFactoryProvider).call();
});

/// 通知リポジトリプロバイダー
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return NotificationRepository();
});

/// フレンドリストリポジトリプロバイダー
final friendListRepositoryProvider = Provider<IFriendListRepository>((ref) {
  return FriendListRepository();
});

/// スケジュールインタラクションリポジトリプロバイダー
final scheduleInteractionRepositoryProvider =
    Provider<IScheduleInteractionRepository>((ref) {
  return ScheduleInteractionRepository();
});

/// 認証状態プロバイダー群
// 認証状態の変更を監視するプロバイダー
final authStateProvider = StreamProvider.autoDispose((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

/// グループ状態プロバイダー群
// グループ状態を管理するNotifierプロバイダー
final groupNotifierProvider =
    AutoDisposeAsyncNotifierProvider<GroupNotifier, GroupState>(
  GroupNotifier.new,
);

/// スケジュール状態プロバイダー群
// スケジュール状態を管理するNotifierプロバイダー
final scheduleNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ScheduleNotifier, ScheduleState>(
  ScheduleNotifier.new,
);

/// リスト状態プロバイダー群
// リスト状態を管理するNotifierプロバイダー
final listNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ListNotifier, ListState>(
  ListNotifier.new,
);

/// 認証済みユーザーのリストを監視するStreamプロバイダー
///
/// 認証状態に基づいて適切にリストを提供します。
/// Application層のビジネスロジックに依存しません。
final userListsStreamProvider =
    StreamProvider.autoDispose<List<UserList>>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (state) {
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value([]);
      }

      return ref
          .watch(listManagerProvider)
          .watchAuthenticatedUserLists(state.user!.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// 認証済みユーザーのグループを監視するStreamプロバイダー
///
/// 認証状態に基づいて適切にグループを提供します。
/// Application層のビジネスロジックに依存しません。
final userGroupsStreamProvider = StreamProvider.autoDispose<List<Group>>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (state) {
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value([]);
      }

      return ref.watch(groupManagerProvider).watchUserGroups(state.user!.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// 統合されたユーザー情報をリアルタイムで監視するStreamプロバイダー
///
/// [userId] 監視対象のユーザーID
///
/// UserManagerを使用して統合されたユーザー情報を提供します。
final userStreamProvider =
    StreamProvider.family<UserModel?, String>((ref, userId) {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (state) {
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value(null);
      }

      return ref.watch(userManagerProvider).watchIntegratedUser(userId);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// 特定のリストをリアルタイムで監視するStreamプロバイダー
///
/// [listId] 監視対象のリストID
final listStreamProvider =
    StreamProvider.family<UserList?, String>((ref, listId) {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (state) {
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value(null);
      }

      return ref.watch(listManagerProvider).watchList(listId);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

/// 認証済みユーザーのフレンド一覧を監視するStreamプロバイダー
///
/// UserManagerを使用してフレンド情報を提供します。
final userFriendsStreamProvider =
    StreamProvider.autoDispose<List<PublicUserModel>>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (state) {
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value([]);
      }

      return ref
          .watch(userManagerProvider)
          .watchAuthenticatedUserFriends(state.user!.id);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// 認証済みユーザーのフレンド一覧を取得するFutureプロバイダー
/// アプリ起動時、承認時、手動更新時にのみデータを再取得する
final userFriendsProvider =
    FutureProvider.autoDispose<List<PublicUserModel>>((ref) async {
  final authState = await ref.watch(authNotifierProvider.future);

  if (authState.status == AuthStatus.authenticated && authState.user != null) {
    return await ref
        .watch(userManagerProvider)
        .getAuthenticatedUserFriends(authState.user!.id);
  } else {
    return [];
  }
});

/// ユーザーのスケジュール一覧をリアルタイムで監視するStreamプロバイダー
///
/// [userId] 監視対象のユーザーID
final userSchedulesStreamProvider =
    StreamProvider.family<List<Schedule>, String>((ref, userId) {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (state) {
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value([]);
      }

      return ref.watch(scheduleRepositoryProvider).watchUserSchedules(userId);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final reactionRepositoryProvider = Provider<ReactionRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  return ReactionRepositoryImpl(firestore);
});

// 現在選択されている日付を保持するプロバイダー
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
