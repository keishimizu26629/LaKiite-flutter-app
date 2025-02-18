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

export 'package:lakiite/application/notification/notification_notifier.dart' show currentUserIdProvider;

// Firebase instances
final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);

// Repository providers
final userRepositoryProvider = Provider<IUserRepository>((ref) {
  final repository = UserRepository();
  ref.onDispose(() {
    // キャッシュをクリア
    (repository).clearCache();
  });
  return repository;
});

final groupRepositoryProvider = Provider<IGroupRepository>((ref) {
  return GroupRepository();
});

final listRepositoryProvider = Provider<IListRepository>((ref) {
  return ListRepository();
});

final scheduleRepositoryProvider = Provider<IScheduleRepository>((ref) {
  return ScheduleRepository();
});

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return NotificationRepository();
});
// Auth state providers
final authStateProvider = StreamProvider.autoDispose((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

final authNotifierProvider = AutoDisposeAsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

// Group state providers
final groupNotifierProvider = AutoDisposeAsyncNotifierProvider<GroupNotifier, GroupState>(
  GroupNotifier.new,
);

// Schedule state providers
final scheduleNotifierProvider = AutoDisposeAsyncNotifierProvider<ScheduleNotifier, ScheduleState>(
  ScheduleNotifier.new,
);

// List state providers
final listNotifierProvider = AutoDisposeAsyncNotifierProvider<ListNotifier, ListState>(
  ListNotifier.new,
);

// リアルタイムリストストリーム
final userListsStreamProvider = StreamProvider.autoDispose<List<UserList>>((ref) {
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

// リアルタイムグループストリーム
final userGroupsStreamProvider = StreamProvider.autoDispose<List<Group>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.when(
    data: (state) {
      if (state.status == AuthStatus.authenticated && state.user != null) {
        return ref.watch(groupRepositoryProvider).watchUserGroups(state.user!.id);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// ユーザーの公開プロフィールストリーム
final publicUserStreamProvider = StreamProvider.family<PublicUserModel?, String>((ref, userId) {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.watchPublicProfile(userId);
});

// ユーザーの非公開プロフィールストリーム
final privateUserStreamProvider = StreamProvider.family<PrivateUserModel?, String>((ref, userId) {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.watchPrivateProfile(userId);
});

// 統合されたユーザー情報ストリーム
final userStreamProvider = StreamProvider.family<UserModel?, String>((ref, userId) async* {
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

// リアルタイムフレンドストリーム
// 特定のリストをリアルタイムで監視するプロバイダー
final listStreamProvider = StreamProvider.family<UserList?, String>((ref, listId) {
  final listRepository = ref.watch(listRepositoryProvider);
  return listRepository.watchList(listId);
});

final userFriendsStreamProvider = StreamProvider.autoDispose<List<PublicUserModel>>((ref) {
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
