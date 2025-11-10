import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/schedule/schedule_notifier.dart';
import 'package:lakiite/application/schedule/schedule_state.dart';

/// スケジュール状態プロバイダー群
///
/// Application層のスケジュール関連プロバイダーを定義します。

/// スケジュール状態を管理するNotifierプロバイダー
final scheduleNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ScheduleNotifier, ScheduleState>(
  ScheduleNotifier.new,
);
