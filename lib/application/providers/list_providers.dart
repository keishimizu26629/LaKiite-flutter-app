import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/list/list_notifier.dart';
import 'package:lakiite/application/list/list_state.dart';

/// リスト状態プロバイダー群
///
/// Application層のリスト関連プロバイダーを定義します。

/// リスト状態を管理するNotifierプロバイダー
final listNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ListNotifier, ListState>(
  ListNotifier.new,
);
