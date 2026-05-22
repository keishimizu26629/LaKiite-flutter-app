import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/application/list/list_notifier.dart';
import 'package:lakiite/application/list/list_state.dart';
import 'package:lakiite/application/schedule/schedule_notifier.dart';
import 'package:lakiite/application/schedule/schedule_state.dart';
import 'package:lakiite/domain/entity/list.dart';
import 'package:lakiite/domain/entity/user.dart';
import '../domain/entity/schedule.dart';

export 'package:lakiite/app/di/providers.dart';
export 'package:lakiite/application/notification/notification_notifier.dart'
    show currentUserIdProvider;
export 'package:lakiite/application/auth/auth_notifier.dart'
    show authNotifierProvider, authRepositoryProvider;
export 'package:lakiite/presentation/calendar/calendar_providers.dart'
    show selectedDateProvider;

/// 認証状態プロバイダー群
// 認証状態の変更を監視するプロバイダー
final authStateProvider = StreamProvider.autoDispose((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges();
});

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
