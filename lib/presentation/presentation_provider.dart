import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tarakite/application/auth/auth_notifier.dart';
import 'package:tarakite/application/auth/auth_state.dart';
import 'package:tarakite/application/group/group_notifier.dart';
import 'package:tarakite/application/group/group_state.dart';
import 'package:tarakite/application/schedule/schedule_notifier.dart';
import 'package:tarakite/application/schedule/schedule_state.dart';
import 'package:tarakite/domain/interfaces/i_group_repository.dart';
import 'package:tarakite/domain/interfaces/i_schedule_repository.dart';
import 'package:tarakite/infrastructure/group_repository.dart';
import 'package:tarakite/infrastructure/schedule_repository.dart';
import 'package:tarakite/domain/entity/group.dart';
import 'package:tarakite/domain/entity/user.dart';

// Firebase instances
final firebaseAuthProvider = Provider((ref) => FirebaseAuth.instance);

// Repository providers
// Note: authRepositoryProvider and userRepositoryProvider are now defined in auth_notifier.dart

final groupRepositoryProvider = Provider<IGroupRepository>((ref) {
  return GroupRepository();
});

final scheduleRepositoryProvider = Provider<IScheduleRepository>((ref) {
  return ScheduleRepository();
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
final userFriendsStreamProvider = StreamProvider.autoDispose<List<PublicUserModel>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return authState.when(
    data: (state) {
      // 認証状態でない場合は即座に空配列を返す
      if (state.status != AuthStatus.authenticated || state.user == null) {
        return Stream.value([]);
      }

      // 認証済みの場合のみユーザー情報の監視を開始
      final userRepository = ref.watch(userRepositoryProvider);
      return userRepository.watchUser(state.user!.id).asyncExpand((user) async* {
        if (user == null) {
          yield [];
        } else {
          // 友達の公開プロフィールのみを取得
          final friendsFutures = user.friends.map((friendId) =>
            userRepository.getFriendPublicProfile(friendId)
          );
          final friends = await Future.wait(friendsFutures);
          yield friends.whereType<PublicUserModel>().toList();
        }
      });
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});
