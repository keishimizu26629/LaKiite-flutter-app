import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/notification_badge.dart';
import '../notification/notification_list_page.dart';
import 'friend_search_view_model.dart';

class FriendSearchPage extends ConsumerStatefulWidget {
  const FriendSearchPage({super.key});

  @override
  ConsumerState<FriendSearchPage> createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends ConsumerState<FriendSearchPage> {
  final TextEditingController searchController = TextEditingController();
  bool isDialogShowing = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(friendSearchViewModelProvider.notifier);
    final state = ref.watch(friendSearchViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('フレンド検索'),
        actions: [
          IconButton(
            icon: const FriendRequestBadge(
              child: Icon(Icons.notifications),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationListPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 検索フィールド
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'ユーザーIDを入力',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    viewModel.searchUser(searchController.text);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (state.isLoading)
              const Center(child: CircularProgressIndicator()),

            // エラーメッセージを下部に表示
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'エラー: ${state.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // 検索結果をポップアップで表示
            Builder(
              builder: (context) {
                if (state.hasValue && state.value != null && !isDialogShowing) {
                  // ポップアップを表示
                  isDialogShowing = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => PopScope(
                        canPop: true,
                        onPopInvoked: (didPop) {
                          setState(() {
                            isDialogShowing = false;
                          });
                          viewModel.resetState();
                        },
                        child: AlertDialog(
                          content: SizedBox(
                            width: 250,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircleAvatar(
                                  radius: 40,
                                  child: Icon(Icons.person, size: 40),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  state.value!.displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'ID: ${state.value!.searchId}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (state.value!.hasPendingRequest)
                                  ElevatedButton(
                                    onPressed: null, // 無効化
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                    ),
                                    child: const Text('申請済み'),
                                  )
                                else
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            isDialogShowing = false;
                                          });
                                          viewModel.resetState();
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('キャンセル'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final scaffoldMessenger =
                                              ScaffoldMessenger.of(context);
                                          final navigator =
                                              Navigator.of(context);
                                          await viewModel.sendFriendRequest(
                                              state.value!.id);
                                          if (mounted) {
                                            setState(() {
                                              isDialogShowing = false;
                                            });
                                            navigator.pop();
                                            searchController.clear();
                                            if (viewModel.message != null) {
                                              scaffoldMessenger.showSnackBar(
                                                SnackBar(
                                                  content:
                                                      Text(viewModel.message!),
                                                  duration: const Duration(
                                                      seconds: 2),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        child: const Text('申請する'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }
}
