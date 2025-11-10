import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 共通プロバイダー群
///
/// 複数のFeatureで使用される共通のプロバイダーを定義します。

/// 現在選択されている日付を保持するプロバイダー
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});
