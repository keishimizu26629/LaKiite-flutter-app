import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/schedule/schedule_notifier.dart';
import 'package:lakiite/application/schedule/schedule_state.dart';
import 'package:lakiite/di/repository_providers.dart';
import '../../domain/entity/schedule.dart';

/// スケジュール状態プロバイダー群
///
/// スケジュール関連のプロバイダーを定義します。

/// スケジュール状態を管理するNotifierプロバイダー
final scheduleNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ScheduleNotifier, ScheduleState>(
  ScheduleNotifier.new,
);

/// ユーザーのスケジュール一覧をリアルタイムで監視するStreamプロバイダー
///
/// [userId] 監視対象のユーザーID
final userSchedulesStreamProvider =
    StreamProvider.family<List<Schedule>, String>(
  (ref, userId) =>
      ref.watch(scheduleRepositoryProvider).watchUserSchedules(userId),
);
