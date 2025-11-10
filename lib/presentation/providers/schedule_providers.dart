import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/domain/service/service_provider.dart';
import '../../domain/entity/schedule.dart';

/// スケジュール状態プロバイダー群
///
/// Presentation層のスケジュール関連プロバイダーを定義します。

/// Application層のNotifierプロバイダーをexport
export 'package:lakiite/application/providers/schedule_providers.dart'
    show scheduleNotifierProvider;

/// ユーザーのスケジュール一覧をリアルタイムで監視するStreamプロバイダー
///
/// [userId] 監視対象のユーザーID
/// ScheduleManager経由でアクセスし、エンリッチメント済みのスケジュールを提供します。
final userSchedulesStreamProvider =
    StreamProvider.family<List<Schedule>, String>(
  (ref, userId) =>
      ref.watch(scheduleManagerProvider).watchUserSchedules(userId),
);
