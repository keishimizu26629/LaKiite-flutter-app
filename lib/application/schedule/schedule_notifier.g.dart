// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$scheduleNotifierHash() => r'7bc9b7af8c0b58843ead911fa97d719f7bbbfb61';

/// スケジュール状態を管理するNotifierクラス
///
/// アプリケーション内でのスケジュール操作に関する以下の機能を提供します:
/// - スケジュールの作成・更新・削除
/// - グループ別のスケジュール取得
/// - ユーザー別のスケジュール監視
///
/// Riverpodの状態管理システムと統合され、
/// アプリケーション全体でスケジュール状態を共有します。
///
/// Copied from [ScheduleNotifier].
@ProviderFor(ScheduleNotifier)
final scheduleNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ScheduleNotifier, ScheduleState>.internal(
  ScheduleNotifier.new,
  name: r'scheduleNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$scheduleNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ScheduleNotifier = AutoDisposeAsyncNotifier<ScheduleState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
