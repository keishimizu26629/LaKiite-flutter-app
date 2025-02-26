import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:lakiite/domain/entity/group.dart';

part 'group_state.freezed.dart';

/// グループ操作の状態を表現するクラス
///
/// 状態の種類:
/// - 初期状態: アプリケーション起動時
/// - ローディング状態: データ取得/更新中
/// - 取得完了状態: データ取得/更新成功
/// - エラー状態: 操作失敗
///
/// 実装:
/// - [freezed]パッケージによるイミュータブルな状態管理
/// - Union型による型安全な状態遷移
@freezed
class GroupState with _$GroupState {
  /// 初期状態を表すファクトリーメソッド
  ///
  /// 用途:
  /// - アプリケーション起動時の初期状態
  /// - グループ操作開始前の状態リセット
  ///
  /// 特徴:
  /// - データを持たない空の状態
  /// - 操作可能な準備完了状態
  const factory GroupState.initial() = _Initial;

  /// ローディング状態を表すファクトリーメソッド
  ///
  /// 用途:
  /// - グループ情報の取得中
  /// - グループ情報の更新処理中
  ///
  /// 特徴:
  /// - 処理中であることをUIに通知
  /// - ユーザー操作を一時的に制限
  const factory GroupState.loading() = _Loading;

  /// データ取得完了状態を表すファクトリーメソッド
  ///
  /// パラメータ:
  /// - [groups] 取得したグループのリスト
  ///
  /// 用途:
  /// - グループ情報の取得成功時
  /// - グループ情報の更新成功時
  ///
  /// 特徴:
  /// - 最新のグループ情報を保持
  /// - UIでのデータ表示が可能
  const factory GroupState.loaded(List<Group> groups) = _Loaded;

  /// エラー状態を表すファクトリーメソッド
  ///
  /// パラメータ:
  /// - [message] エラーの詳細メッセージ
  ///
  /// 用途:
  /// - グループ操作失敗時のエラー表示
  /// - エラー状態からのリカバリー処理
  ///
  /// 特徴:
  /// - エラー内容をユーザーに通知可能
  /// - エラーハンドリングの起点として使用
  const factory GroupState.error(String message) = _Error;
}
