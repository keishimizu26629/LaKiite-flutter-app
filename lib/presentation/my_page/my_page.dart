import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'my_page_view_model.dart';
import '../presentation_provider.dart';
import '../widgets/banner_ad_widget.dart';
import '../settings/settings_page.dart';
import 'widgets/profile_card.dart';
import 'widgets/section_header.dart';
import 'widgets/short_bio_card.dart';
import 'widgets/schedule_list.dart';
import 'widgets/profile_edit_dialog.dart';

/// マイページを表示するウィジェット
///
/// ユーザーのプロフィール情報、予定一覧を表示し、プロフィールの編集機能を提供します。
class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

/// MyPageの状態を管理するクラス
class _MyPageState extends ConsumerState<MyPage> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // iOS環境でのプラットフォームビュー初期化のための遅延処理
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeProfilePage();
    });
  }

  /// プロフィール画面の初期化処理
  /// iOS環境でのクラッシュを防ぐため、プラットフォームビューの初期化を遅延させる
  Future<void> _initializeProfilePage() async {
    try {
      // iOS環境では初期化を遅延させる
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!mounted) return;

      // 認証状態を監視してユーザーデータを読み込む
      final authState = ref.read(authNotifierProvider);
      await authState.when(
        data: (state) async {
          if (state.user != null && mounted) {
            await ref
                .read(myPageViewModelProvider.notifier)
                .loadUser(state.user!.id);
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
            }
          }
        },
        loading: () async {
          // 認証状態がローディング中の場合は待機
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
            await _initializeProfilePage();
          }
        },
        error: (error, stack) async {
          // 認証エラーの場合はログインページに遷移
          if (mounted) {
            context.go('/login');
          }
        },
      );
    } catch (e) {
      // 初期化に失敗した場合のエラーハンドリング
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 初期化が完了していない場合はローディング表示
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'マイページ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final userState = ref.watch(myPageViewModelProvider);
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'マイページ',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              context.push(SettingsPage.path);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: authState.when(
                  data: (auth) {
                    // 認証状態が未認証の場合はログインページに遷移
                    if (!auth.isAuthenticated || auth.user == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          context.go('/login');
                        }
                      });
                      return const Center(child: CircularProgressIndicator());
                    }

                    return userState.when(
                      data: (user) {
                        // ユーザーデータがnullまたは不完全な場合の処理
                        if (user == null) {
                          return const _EmptyUserState();
                        }

                        // ユーザーデータの整合性チェック
                        if (!_isUserDataValid(user)) {
                          return const _InvalidUserDataState();
                        }

                        return RefreshIndicator(
                          onRefresh: () async {
                            await ref
                                .read(myPageViewModelProvider.notifier)
                                .loadUser(user.id);
                          },
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ProfileCard(
                                  user: user,
                                  onEditPressed: () {
                                    _showProfileEditDialog(context, user);
                                  },
                                ),
                                const SizedBox(height: 24),
                                const SectionHeader(
                                  icon: Icons.description_outlined,
                                  title: '一言コメント',
                                ),
                                const SizedBox(height: 16),
                                ShortBioCard(
                                    shortBio:
                                        user.publicProfile.shortBio ?? ''),
                                const SizedBox(height: 24),
                                const SectionHeader(
                                  icon: Icons.event,
                                  title: '予定一覧',
                                ),
                                const SizedBox(height: 16),
                                ScheduleList(userId: user.id),
                              ],
                            ),
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => _ErrorState(error: error),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => _ErrorState(error: error),
                ),
              ),
            ),
            const SizedBox(
              height: 50,
              child: BannerAdWidget(uniqueId: 'my_page_ad'),
            ),
          ],
        ),
      ),
    );
  }

  /// ユーザーデータの妥当性をチェック
  bool _isUserDataValid(dynamic user) {
    if (user == null) return false;

    // 基本的なプロパティの存在チェック
    try {
      // ユーザーIDが存在するかチェック
      if (user.id == null || user.id.isEmpty) return false;

      // 表示名が存在するかチェック
      if (user.displayName == null) return false;

      // publicProfileが存在するかチェック
      if (user.publicProfile == null) return false;

      return true;
    } catch (e) {
      // プロパティアクセスでエラーが発生した場合は無効とみなす
      return false;
    }
  }

  /// プロフィール編集ダイアログを表示
  void _showProfileEditDialog(BuildContext context, dynamic user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ProfileEditDialog(
        user: user,
        onImageEdit: () async {
          if (!mounted) return;
          final scaffoldMessenger = ScaffoldMessenger.of(dialogContext);
          try {
            await ref.read(myPageViewModelProvider.notifier).pickImage();
          } catch (e) {
            if (mounted) {
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text('画像の選択に失敗しました: $e')),
              );
            }
          }
        },
      ),
    );
  }
}

/// ユーザーが見つからない場合の表示ウィジェット
class _EmptyUserState extends StatelessWidget {
  const _EmptyUserState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ユーザー情報が見つかりません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.go('/login');
            },
            child: const Text('ログイン画面に戻る'),
          ),
        ],
      ),
    );
  }
}

/// ユーザーデータが無効な場合の表示ウィジェット
class _InvalidUserDataState extends StatelessWidget {
  const _InvalidUserDataState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_outlined,
            size: 64,
            color: Colors.orange[400],
          ),
          const SizedBox(height: 16),
          Text(
            'ユーザーデータに問題があります',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'アプリを再起動してください',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.go('/login');
            },
            child: const Text('ログイン画面に戻る'),
          ),
        ],
      ),
    );
  }
}

/// エラー発生時の表示ウィジェット
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'エラーが発生しました',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.go('/login');
            },
            child: const Text('ログイン画面に戻る'),
          ),
        ],
      ),
    );
  }
}
