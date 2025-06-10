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
    show authRepositoryProvider;

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

/// 認証済みユーザーのリストを監視するStreamプロバイダー
///
/// 認証状態に基づいて適切にリストを提供します。
/// Application層のビジネスロジックに依存しません。
final userListsStreamProvider =
    StreamProvider.autoDispose<List<UserList>>((ref) async* {
  final authState = await ref.watch(authNotifierProvider.future);

  if (authState.status == AuthStatus.authenticated && authState.user != null) {
    await for (final lists in ref
        .watch(listManagerProvider)
        .watchAuthenticatedUserLists(authState.user!.id)) {
      yield lists;
    }
  } else {
    yield [];
  }
});

/// 認証済みユーザーのグループを監視するStreamプロバイダー
///
/// 認証状態に基づいて適切にグループを提供します。
/// Application層のビジネスロジックに依存しません。
final userGroupsStreamProvider =
    StreamProvider.autoDispose<List<Group>>((ref) async* {
  final authState = await ref.watch(authNotifierProvider.future);

  if (authState.status == AuthStatus.authenticated && authState.user != null) {
    await for (final groups in ref
        .watch(groupManagerProvider)
        .watchUserGroups(authState.user!.id)) {
      yield groups;
    }
  } else {
    yield [];
  }
});

/// 統合されたユーザー情報をリアルタイムで監視するStreamプロバイダー
///
/// [userId] 監視対象のユーザーID
///
/// UserManagerを使用して統合されたユーザー情報を提供します。
final userStreamProvider =
    StreamProvider.family<UserModel?, String>((ref, userId) {
  return ref.watch(userManagerProvider).watchIntegratedUser(userId);
});

/// 特定のリストをリアルタイムで監視するStreamプロバイダー
///
/// [listId] 監視対象のリストID
final listStreamProvider =
    StreamProvider.family<UserList?, String>((ref, listId) {
  return ref.watch(listManagerProvider).watchList(listId);
});

/// 認証済みユーザーのフレンド一覧を監視するStreamプロバイダー
///
/// UserManagerを使用してフレンド情報を提供します。
final userFriendsStreamProvider =
    StreamProvider.autoDispose<List<PublicUserModel>>((ref) async* {
  final authState = await ref.watch(authNotifierProvider.future);

  if (authState.status == AuthStatus.authenticated && authState.user != null) {
    await for (final friends in ref
        .watch(userManagerProvider)
        .watchAuthenticatedUserFriends(authState.user!.id)) {
      yield friends;
    }
  } else {
    yield [];
  }
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
    StreamProvider.family<List<Schedule>, String>(
  (ref, userId) =>
      ref.watch(scheduleRepositoryProvider).watchUserSchedules(userId),
);

final reactionRepositoryProvider = Provider<ReactionRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  return ReactionRepositoryImpl(firestore);
});

// 現在選択されている日付を保持するプロバイダー
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
