import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/presentation_provider.dart';
import '../widgets/schedule_tile.dart';
import '../../utils/logger.dart';

class FriendProfilePage extends ConsumerWidget {
  final String userId;

  const FriendProfilePage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicProfileAsync = ref.watch(publicUserStreamProvider(userId));
    // スケジュールの状態を直接監視
    final scheduleState = ref.watch(scheduleNotifierProvider);
    // 自分自身のユーザーIDも取得
    final currentUserId = ref.watch(authNotifierProvider).value?.user?.id;

    AppLogger.debug('FriendProfilePage: 表示中のユーザーID: $userId');
    AppLogger.debug('FriendProfilePage: 現在のユーザーID: $currentUserId');

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
      ),
      body: publicProfileAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('ユーザーが見つかりません'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // プロバイダーを再読み込み
              ref.invalidate(publicUserStreamProvider(userId));
              ref.invalidate(scheduleNotifierProvider);

              // 完了を待つ
              await Future.wait([
                ref.refresh(publicUserStreamProvider(userId).future),
                ref.refresh(scheduleNotifierProvider.future),
                // 視覚的にわかりやすくするために少し待つ
                Future.delayed(const Duration(milliseconds: 300))
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            backgroundImage: user.iconUrl != null
                                ? NetworkImage(user.iconUrl!)
                                : null,
                            child: user.iconUrl == null
                                ? const Icon(Icons.person,
                                    size: 40, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    await Clipboard.setData(
                                      ClipboardData(
                                          text: user.searchId.toString()),
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('検索IDをコピーしました')),
                                      );
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      Text(
                                        '@${user.searchId}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.copy,
                                        size: 14,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (user.shortBio != null && user.shortBio!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionHeader(
                      icon: Icons.description_outlined,
                      title: '一言コメント',
                    ),
                    const SizedBox(height: 16),
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Text(
                          user.shortBio!.trim(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _SectionHeader(
                    icon: Icons.event,
                    title: '予定一覧',
                  ),
                  const SizedBox(height: 16),
                  scheduleState.when(
                    data: (state) => state.maybeWhen(
                      loaded: (allSchedules) {
                        AppLogger.debug(
                            'FriendProfilePage: 全スケジュール数: ${allSchedules.length}');

                        // 本日以降のスケジュールをフィルタリング
                        final today = DateTime.now().toUtc().toLocal();
                        final todayStart =
                            DateTime(today.year, today.month, today.day);

                        // このユーザーが所有者となっている予定だけを表示
                        // 現在日以降のものだけを絞り込み
                        final userSchedules = allSchedules
                            .where((s) =>
                                // このユーザーが作成した予定
                                s.ownerId == userId &&
                                // 現在日以降の予定
                                s.endDateTime.isAfter(todayStart) &&
                                // かつ自分が閲覧可能な予定（visibleToに自分のIDが含まれている）
                                (currentUserId == null ||
                                    s.visibleTo.contains(currentUserId)))
                            .toList();

                        AppLogger.debug(
                            'FriendProfilePage: フィルタリング後のスケジュール数: ${userSchedules.length}');

                        if (userSchedules.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '現在表示できる予定がありません',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '今後の予定が登録されると表示されます',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // 日付でソート
                        userSchedules.sort((a, b) =>
                            a.startDateTime.compareTo(b.startDateTime));

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: userSchedules.length,
                          itemBuilder: (context, index) {
                            final schedule = userSchedules[index];
                            return ScheduleTile(
                              schedule: schedule,
                              currentUserId: currentUserId ?? '',
                              showOwner: false,
                              showEditButton: false,
                              isTimelineView: false,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                            );
                          },
                        );
                      },
                      orElse: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Text('エラーが発生しました: $error'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('エラーが発生しました: $error'),
        ),
      ),
    );
  }
}

/// セクションヘッダーウィジェット
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}
