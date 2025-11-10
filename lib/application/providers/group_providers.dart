import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lakiite/application/group/group_notifier.dart';
import 'package:lakiite/application/group/group_state.dart';

/// グループ状態プロバイダー群
///
/// Application層のグループ関連プロバイダーを定義します。

/// グループ状態を管理するNotifierプロバイダー
final groupNotifierProvider =
    AutoDisposeAsyncNotifierProvider<GroupNotifier, GroupState>(
  GroupNotifier.new,
);
