import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entity/user.dart';
import '../../presentation/presentation_provider.dart';
import '../widgets/schedule_tile.dart';
import '../../utils/logger.dart';

class FriendProfilePage extends ConsumerWidget {
  const FriendProfilePage({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 自分自身のユーザーIDを取得
    final currentUserAsync = ref.watch(authNotifierProvider);
    final currentUserId = currentUserAsync.value?.user?.id;

    // 自分自身が閲覧可能な予定を取得（マイページと同じ方法）
    final schedulesAsync = currentUserId != null
        ? ref.watch(userSchedulesStreamProvider(currentUserId))
        : const AsyncValue<List<dynamic>>.loading();

    AppLogger.debug('FriendProfilePage: 表示中のユーザーID: $userId');
    AppLogger.debug('FriendProfilePage: 現在のユーザーID: $currentUserId');

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
      ),
      body: FutureBuilder<PublicUserModel?>(
        future: ref.read(userRepositoryProvider).getFriendPublicProfile(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('ユーザーが見つかりません'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              // 自分が閲覧可能な予定の再読み込み
              if (currentUserId != null) {
                ref.invalidate(userSchedulesStreamProvider(currentUserId));
              }

              // 視覚的なフィードバックのために少し待つ
              await Future.delayed(const Duration(milliseconds: 500));
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
                  // StreamProviderを使用した予定一覧表示
                  schedulesAsync.when(
                    data: (schedules) {
                      AppLogger.debug(
                          'FriendProfilePage: 全スケジュール数: ${schedules.length}');

                      // 本日以降のスケジュールをフィルタリング
                      final today = DateTime.now().toUtc().toLocal();
                      final todayStart =
                          DateTime(today.year, today.month, today.day);

                      // この友人が所有者となっている予定だけを表示（キーポイント）
                      final userSchedules = schedules
                          .where((s) =>
                              // この友人が作成した予定
                              // ignore: avoid_dynamic_calls
                              s.ownerId == userId &&
                              // 現在日以降の予定
                              // ignore: avoid_dynamic_calls
                              s.endDateTime.isAfter(todayStart))
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
                      userSchedules.sort(
                          // ignore: avoid_dynamic_calls
                          (a, b) => a.startDateTime.compareTo(b.startDateTime));

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
      ),
    );
  }
}

/// セクションヘッダーウィジェット
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

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
