import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'my_page_view_model.dart';
import '../presentation_provider.dart';
import '../widgets/banner_ad_widget.dart';
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
  @override
  void initState() {
    super.initState();
    // マウント後にユーザーデータを読み込む
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authNotifierProvider).whenData((state) {
        if (state.user != null) {
          ref.read(myPageViewModelProvider.notifier).loadUser(state.user!.id);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(myPageViewModelProvider);

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
              context.push('/settings');
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
                child: userState.when(
                  data: (user) {
                    if (user == null) {
                      return const _EmptyUserState();
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
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (dialogContext) => ProfileEditDialog(
                                    user: user,
                                    onImageEdit: () async {
                                      if (!mounted) return;
                                      final scaffoldMessenger =
                                          ScaffoldMessenger.of(dialogContext);
                                      try {
                                        await ref
                                            .read(myPageViewModelProvider
                                                .notifier)
                                            .pickImage();
                                      } catch (e) {
                                        if (mounted) {
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                                content:
                                                    Text('画像の選択に失敗しました: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            const SectionHeader(
                              icon: Icons.description_outlined,
                              title: '一言コメント',
                            ),
                            const SizedBox(height: 16),
                            ShortBioCard(shortBio: user.publicProfile.shortBio),
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
                  error: (error, stack) => const _ErrorState(),
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
        ],
      ),
    );
  }
}

/// エラー発生時の表示ウィジェット
class _ErrorState extends StatelessWidget {
  const _ErrorState();

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
        ],
      ),
    );
  }
}
