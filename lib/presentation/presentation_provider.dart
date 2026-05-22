import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/list/list_notifier.dart';
import 'package:lakiite/application/list/list_state.dart';
import 'package:lakiite/application/schedule/schedule_notifier.dart';
import 'package:lakiite/application/schedule/schedule_state.dart';

export 'package:lakiite/app/di/providers.dart';
export 'package:lakiite/application/notification/notification_notifier.dart'
    show currentUserIdProvider;
export 'package:lakiite/application/auth/auth_notifier.dart'
    show authNotifierProvider, authRepositoryProvider;
export 'package:lakiite/presentation/calendar/calendar_providers.dart'
    show selectedDateProvider;
export 'package:lakiite/presentation/calendar/schedule_providers.dart'
    show userSchedulesStreamProvider;
export 'package:lakiite/presentation/list/list_providers.dart'
    show listStreamProvider, userListsStreamProvider;
export 'package:lakiite/presentation/friend/friend_providers.dart'
    show userFriendsProvider, userFriendsStreamProvider;
export 'package:lakiite/presentation/user/user_providers.dart'
    show userStreamProvider;

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
