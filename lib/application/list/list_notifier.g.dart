// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'list_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$listNotifierHash() => r'0dc68b71436c57ccb2cac8ddff01ac571ef9b77e';

/// プライベートリスト状態を管理するNotifierクラス
///
/// アプリケーション内でのプライベートリスト操作に関する以下の機能を提供します:
/// - リストの作成・更新・削除
/// - リストメンバーの追加・削除（非公開・通知なし）
/// - リスト情報の取得と監視
///
/// Riverpodの状態管理システムと統合され、
/// アプリケーション全体でリスト状態を共有します。
///
/// Copied from [ListNotifier].
@ProviderFor(ListNotifier)
final listNotifierProvider =
    AutoDisposeAsyncNotifierProvider<ListNotifier, ListState>.internal(
  ListNotifier.new,
  name: r'listNotifierProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$listNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ListNotifier = AutoDisposeAsyncNotifier<ListState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
