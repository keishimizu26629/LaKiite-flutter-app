import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/presentation_provider.dart';
import '../widgets/schedule_tile.dart';

class FriendProfilePage extends ConsumerWidget {
  final String userId;

  const FriendProfilePage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicProfileAsync = ref.watch(publicUserStreamProvider(userId));
    final schedulesAsync = ref.watch(userSchedulesStreamProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
      ),
      body: publicProfileAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('ユーザーが見つかりません'));
          }

          return SingleChildScrollView(
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
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                schedulesAsync.when(
                  data: (schedules) {
                    final userSchedules =
                        schedules.where((s) => s.ownerId == userId).toList();

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
                              '予定がありません',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    userSchedules.sort(
                        (a, b) => a.startDateTime.compareTo(b.startDateTime));

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: userSchedules.length,
                      itemBuilder: (context, index) {
                        final schedule = userSchedules[index];
                        return ScheduleTile(
                          schedule: schedule,
                          currentUserId: userId,
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
