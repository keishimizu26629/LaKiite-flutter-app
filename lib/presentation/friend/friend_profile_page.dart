import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/presentation_provider.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/default_user_icon.dart';
import '../widgets/schedule_tile.dart';
import '../my_page/widgets/section_header.dart';
import '../calendar/schedule_detail_page.dart';

class FriendProfilePage extends ConsumerWidget {
  final String userId;

  const FriendProfilePage({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final publicProfileAsync = ref.watch(publicUserStreamProvider(userId));
    final currentUserId = ref.read(authNotifierProvider).value?.user?.id ?? '';
    final userSchedulesAsync =
        ref.watch(visibleAndOwnedSchedulesStreamProvider((
      visibleToUserId: currentUserId,
      ownerId: userId,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'プロフィール',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: publicProfileAsync.when(
                data: (user) {
                  if (user == null) {
                    return const Center(child: Text('ユーザーが見つかりません'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(publicUserStreamProvider(userId));
                      ref.invalidate(visibleAndOwnedSchedulesStreamProvider((
                        visibleToUserId: currentUserId,
                        ownerId: userId,
                      )));
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // プロフィールカード
                          Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  user.iconUrl != null
                                      ? CircleAvatar(
                                          radius: 40,
                                          backgroundImage:
                                              NetworkImage(user.iconUrl!),
                                        )
                                      : const DefaultUserIcon(size: 80),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.displayName,
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // IDコピー機能
                                        GestureDetector(
                                          onTap: () async {
                                            await Clipboard.setData(
                                              ClipboardData(
                                                  text:
                                                      user.searchId.toString()),
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content:
                                                        Text('検索IDをコピーしました')),
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
                                                color: Theme.of(context)
                                                    .primaryColor,
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

                          // 一言コメント
                          if (user.shortBio != null &&
                              user.shortBio!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const SectionHeader(
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
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
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

                          // 予定一覧
                          const SizedBox(height: 24),
                          const SectionHeader(
                            icon: Icons.event,
                            title: '予定一覧',
                          ),
                          const SizedBox(height: 16),
                          userSchedulesAsync.when(
                            data: (schedules) {
                              if (schedules.isEmpty) {
                                return Card(
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    child: const Center(
                                      child: Text(
                                        '予定はありません',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // 日付でソート
                              schedules.sort((a, b) =>
                                  a.startDateTime.compareTo(b.startDateTime));

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: schedules.length,
                                itemBuilder: (context, index) {
                                  final schedule = schedules[index];
                                  return ScheduleTile(
                                    schedule: schedule,
                                    currentUserId: ref
                                            .read(authNotifierProvider)
                                            .value
                                            ?.user
                                            ?.id ??
                                        '',
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text('エラーが発生しました: $error'),
                ),
              ),
            ),
            const SizedBox(
              height: 50,
              child: BannerAdWidget(),
            ),
          ],
        ),
      ),
    );
  }
}
