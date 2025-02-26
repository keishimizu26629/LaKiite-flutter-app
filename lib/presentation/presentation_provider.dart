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

/// Firebase認証インスタンスを提供するプロバイダー
final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);

/// リポジトリプロバイダー群
// ユーザーリポジトリプロバイダー
final userRepositoryProvider = Provider<IUserRepository>((ref) {
  final repository = UserRepository();
  ref.onDispose(() {
    // キャッシュをクリア
    (repository).clearCache();
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
  return ScheduleRepository(FriendListRepository());
});

/// 通知リポジトリプロバイダー
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return NotificationRepository();
});

/// 認証状態プロバイダー群
// 認証状態の変更を監視するプロバイダー
final authStateProvider = StreamProvider.autoDispose((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

/// 認証状態を管理するNotifierプロバイダー
final authNotifierProvider =
    AutoDisposeAsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

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

/// ユーザーのリストをリアルタイムで監視するStreamプロバイダー
final userListsStreamProvider =
    StreamProvider.autoDispose<List<UserList>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.when(
    data: (state) {
      if (state.status == AuthStatus.authenticated && state.user != null) {
        return ref.watch(listRepositoryProvider).watchUserLists(state.user!.id);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// ユーザーのグループをリアルタイムで監視するStreamプロバイダー
final userGroupsStreamProvider = StreamProvider.autoDispose<List<Group>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.when(
    data: (state) {
      if (state.status == AuthStatus.authenticated && state.user != null) {
        return ref
            .watch(groupRepositoryProvider)
            .watchUserGroups(state.user!.id);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// ユーザーの公開プロフィールをリアルタイムで監視するStreamプロバイダー
///
/// [userId] 監視対象のユーザーID
final publicUserStreamProvider =
    StreamProvider.family<PublicUserModel?, String>((ref, userId) {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.watchPublicProfile(userId);
});

/// ユーザーの非公開プロフィールをリアルタイムで監視するStreamプロバイダー
///
/// [userId] 監視対象のユーザーID
final privateUserStreamProvider =
    StreamProvider.family<PrivateUserModel?, String>((ref, userId) {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.watchPrivateProfile(userId);
});

/// 統合されたユーザー情報をリアルタイムで監視するStreamプロバイダー
///
/// [userId] 監視対象のユーザーID
///
/// 公開プロフィールと非公開プロフィールを統合して[UserModel]として提供します。
final userStreamProvider =
    StreamProvider.family<UserModel?, String>((ref, userId) async* {
  final publicProfileAsync = ref.watch(publicUserStreamProvider(userId));
  final privateProfileAsync = ref.watch(privateUserStreamProvider(userId));

  if (publicProfileAsync is AsyncData && privateProfileAsync is AsyncData) {
    final publicProfile = publicProfileAsync.value;
    final privateProfile = privateProfileAsync.value;

    if (publicProfile != null && privateProfile != null) {
      yield UserModel(
        publicProfile: publicProfile,
        privateProfile: privateProfile,
      );
    } else {
      yield null;
    }
  } else {
    yield null;
  }
});

/// 特定のリストをリアルタイムで監視するStreamプロバイダー
///
/// [listId] 監視対象のリストID
final listStreamProvider =
    StreamProvider.family<UserList?, String>((ref, listId) {
  final listRepository = ref.watch(listRepositoryProvider);
  return listRepository.watchList(listId);
});

/// ユーザーのフレンド一覧をリアルタイムで監視するStreamプロバイダー
final userFriendsStreamProvider =
    StreamProvider.autoDispose<List<PublicUserModel>>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (state) {
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value([]);
      }

      final userRepository = ref.watch(userRepositoryProvider);

      // ユーザー情報のストリームを監視
      return userRepository.watchUser(state.user!.id).asyncMap((user) async {
        if (user == null || user.friends.isEmpty) {
          return [];
        }

        // 一度に全フレンドのプロフィールを取得
        final profiles = await userRepository.getPublicProfiles(user.friends);
        return profiles;
      });
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// ユーザーのスケジュール一覧をリアルタイムで監視するStreamプロバイダー
///
/// [userId] 監視対象のユーザーID
final userSchedulesStreamProvider =
    StreamProvider.family<List<Schedule>, String>(
  (ref, userId) =>
      ref.watch(scheduleRepositoryProvider).watchUserSchedules(userId),
);

/// ユーザーが所有するスケジュール一覧をリアルタイムで監視するStreamプロバイダー
///
/// [userId] 監視対象のユーザーID
final userOwnedSchedulesStreamProvider =
    StreamProvider.family<List<Schedule>, String>(
  (ref, userId) =>
      ref.watch(scheduleRepositoryProvider).watchUserOwnedSchedules(userId),
);

/// 特定のユーザーに公開されていて、特定のユーザーが所有するスケジュール一覧をリアルタイムで監視するStreamプロバイダー
///
/// [params] パラメータ（visibleToUserId, ownerId）
final visibleAndOwnedSchedulesStreamProvider = StreamProvider.family<
    List<Schedule>, ({String visibleToUserId, String ownerId})>(
  (ref, params) =>
      ref.watch(scheduleRepositoryProvider).watchVisibleAndOwnedSchedules(
            params.visibleToUserId,
            params.ownerId,
          ),
);

final reactionRepositoryProvider = Provider<ReactionRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  return ReactionRepositoryImpl(firestore);
});
