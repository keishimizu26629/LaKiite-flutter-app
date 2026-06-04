import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_notifier.dart';
import '../../application/auth/auth_state.dart';
import '../../application/notification/notification_notifier.dart'
    show sentNotificationsByTypeProvider;
import '../../domain/entity/notification.dart' as domain;
import 'friend_providers.dart';
import '../friend/friend_search_page.dart';
import '../friend/friend_profile_page.dart';
import '../widgets/notification_button.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/default_user_icon.dart';

/// フレンドリストを表示するページ。
class FriendListPage extends ConsumerStatefulWidget {
  const FriendListPage({super.key});

  @override
  ConsumerState<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends ConsumerState<FriendListPage> {
  // フローティングボタンをキャッシュするための変数
  late final Widget _friendTabFAB;

  @override
  void initState() {
    super.initState();
    // フローティングボタンを事前に構築
    _friendTabFAB = FloatingActionButton(
      heroTag: 'friend_search_fab',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const FriendSearchPage()),
        );
      },
      child: const Icon(Icons.person_add),
    );
  }

  // フレンドタブの内容を構築します。
  Widget _buildFriendTabContent() {
    // StreamProviderに変更してリアルタイム更新を実現
    final friendsAsync = ref.watch(userFriendsStreamProvider);
    final sentFriendRequestsAsync = ref.watch(
      sentNotificationsByTypeProvider(domain.NotificationType.friend),
    );

    return friendsAsync.when(
      data: (friends) {
        final pendingRequests = sentFriendRequestsAsync.valueOrNull
                ?.where(
                  (request) =>
                      request.status == domain.NotificationStatus.pending,
                )
                .toList() ??
            const <domain.Notification>[];

        return RefreshIndicator(
          onRefresh: () async {
            // StreamProviderは自動更新されるため、最小限の更新のみ
            ref.invalidate(userFriendsStreamProvider);
            ref.invalidate(
              sentNotificationsByTypeProvider(domain.NotificationType.friend),
            );
          },
          child: ListView(
            key: const PageStorageKey('friend_list'), // キーを追加してスクロール位置を保持
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 58,
            ),
            children: [
              if (friends.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 112, bottom: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'フレンドがいません',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              else
                ...friends.map(
                  (friend) => Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: friend.iconUrl != null
                          ? CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(friend.iconUrl!),
                            )
                          : const DefaultUserIcon(size: 48),
                      title: Text(
                        friend.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        friend.shortBio ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                FriendProfilePage(userId: friend.id),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (sentFriendRequestsAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (pendingRequests.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 8),
                  child: Text(
                    '申請中',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                ...pendingRequests.map((request) {
                  final displayName =
                      request.receiveUserDisplayName ?? request.receiveUserId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: const CircleAvatar(
                        radius: 24,
                        child: Icon(Icons.hourglass_empty),
                      ),
                      title: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '承認待ち',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
    );
  }

  // ウィジェットのUIを構築します。
  ///
  /// フレンドリストを表示します。
  /// また、通知バッジ付きのアプリバーと広告バナーも含まれます。
  ///
  /// [context] - ウィジェットのビルドコンテキスト
  /// [return] - 構築されたウィジェット
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return authState.when(
      data: (state) {
        if (state.status != AuthStatus.authenticated || state.user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'フレンド',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: const [NotificationButton()],
          ),
          floatingActionButton: Padding(
            key: const ValueKey('friend_list_fab'),
            padding: const EdgeInsets.only(bottom: 58),
            child: _friendTabFAB,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: Column(
            children: [
              Expanded(child: _buildFriendTabContent()),
              const SizedBox(
                height: 50,
                child: BannerAdWidget(uniqueId: 'friend_list_page_ad'),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('エラーが発生しました: $error'))),
    );
  }
}
