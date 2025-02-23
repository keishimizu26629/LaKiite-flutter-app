// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$groupNotifierHash() => r'fc97531d9e579b47ce34a2d550bda2304c45f603';

/// グループ状態を管理するNotifierクラス
///
/// アプリケーション内でのグループ操作に関する以下の機能を提供します:
/// - グループの作成・更新・削除
/// - グループメンバーの追加・削除
/// - グループ情報の取得と監視
///
/// Riverpodの状態管理システムと統合され、
/// アプリケーション全体でグループ状態を共有します。
///
/// Copied from [GroupNotifier].
@ProviderFor(GroupNotifier)
final groupNotifierProvider =
    AutoDisposeAsyncNotifierProvider<GroupNotifier, GroupState>.internal(
  GroupNotifier.new,
  name: r'groupNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$groupNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

// ignore: unused_element
typedef _$GroupNotifier = AutoDisposeAsyncNotifier<GroupState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
