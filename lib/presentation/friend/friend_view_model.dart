import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/di/providers.dart';
import '../../domain/entity/user.dart';
import '../../domain/interfaces/i_user_repository.dart';

/// ホーム画面のビューモデルを提供するプロバイダー
///
/// パラメータ:
/// - [ref] Riverpodのプロバイダー参照
///
/// 戻り値:
/// - [HomeViewModel]: 初期化されたビューモデルインスタンス
final homeViewModelProvider =
    StateNotifierProvider<HomeViewModel, AsyncValue<HomeState>>((ref) {
  final userRepository = ref.watch(userRepositoryProvider);
  return HomeViewModel(userRepository);
});

/// ホーム画面の状態を表現するクラス
///
/// プロパティ:
/// - [user] 現在のユーザー情報
/// - [friends] フレンドリスト
class HomeState {
  /// HomeStateのコンストラクタ
  ///
  /// パラメータ:
  /// - [user] 現在のユーザー情報(オプション)
  /// - [friends] フレンドリスト(デフォルトは空リスト)
  HomeState({
    this.user,
    this.friends = const [],
  });

  /// 現在のユーザー情報
  final UserModel? user;

  /// フレンドのリスト
  final List<UserModel> friends;

  /// 状態を更新するためのコピーメソッド
  ///
  /// パラメータ:
  /// - [user] 更新するユーザー情報(オプション)
  /// - [friends] 更新するフレンドリスト(オプション)
  ///
  /// 戻り値:
  /// - [HomeState]: 更新された新しい状態インスタンス
  HomeState copyWith({
    UserModel? user,
    List<UserModel>? friends,
  }) {
    return HomeState(
      user: user ?? this.user,
      friends: friends ?? this.friends,
    );
  }
}

/// ホーム画面のビジネスロジックを管理するビューモデル
///
/// プロパティ:
/// - [_userRepository] ユーザー情報の操作を行うリポジトリ
class HomeViewModel extends StateNotifier<AsyncValue<HomeState>> {
  /// HomeViewModelのコンストラクタ
  ///
  /// パラメータ:
  /// - [_userRepository] ユーザー情報の操作を行うリポジトリ
  HomeViewModel(this._userRepository) : super(const AsyncValue.loading());
  final IUserRepository _userRepository;

  /// ユーザーの関連データを読み込む
  ///
  /// パラメータ:
  /// - [userId] データを読み込むユーザーのID
  ///
  /// 処理内容:
  /// 1. ユーザー情報の取得
  /// 2. フレンド情報の取得
  Future<void> loadUserData(String userId) async {
    try {
      // ローディング状態に設定
      state = const AsyncValue.loading();

      // ユーザー情報を取得
      final user = await _userRepository.getUser(userId);

      // ユーザーが存在しない場合はエラー状態を設定
      if (user == null) {
        state = AsyncValue.error('User not found', StackTrace.current);
        return;
      }

      // フレンド情報を並列で取得
      final friendsFutures =
          user.friends.map((friendId) => _userRepository.getUser(friendId));
      final friends =
          (await Future.wait(friendsFutures)).whereType<UserModel>().toList();

      // 取得したデータで状態を更新
      state = AsyncValue.data(HomeState(
        user: user,
        friends: friends,
      ));
    } catch (e, stack) {
      // エラーが発生した場合はエラー状態を設定
      state = AsyncValue.error(e, stack);
    }
  }
}
