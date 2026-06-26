import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/auth/auth_notifier.dart' as auth;
import '../../infrastructure/friend_invite_link_service.dart';
import '../../infrastructure/providers.dart';
import '../widgets/notification_badge.dart';
import '../notification/notification_list_page.dart';
import 'friend_invite_share_content.dart';
import 'friend_search_qr_scanner_page.dart';
import 'friend_search_view_model.dart';

class FriendSearchPage extends ConsumerStatefulWidget {
  const FriendSearchPage({super.key, this.initialSearchId});

  final String? initialSearchId;

  @override
  ConsumerState<FriendSearchPage> createState() => _FriendSearchPageState();
}

class _FriendSearchPageState extends ConsumerState<FriendSearchPage> {
  final TextEditingController searchController = TextEditingController();
  bool isDialogShowing = false;
  bool _hasHandledInitialSearchId = false;
  bool _isSharingInvite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasHandledInitialSearchId) {
        return;
      }

      final initialSearchId = widget.initialSearchId?.trim();
      if (initialSearchId == null || initialSearchId.isEmpty) {
        return;
      }

      _hasHandledInitialSearchId = true;
      _searchById(
        initialSearchId,
        ref.read(friendSearchViewModelProvider.notifier),
        updateInput: false,
      );
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _searchById(
    String searchId,
    FriendSearchViewModel viewModel, {
    bool updateInput = true,
  }) async {
    final trimmedSearchId = searchId.trim();
    if (trimmedSearchId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('検索IDを入力してください')),
      );
      return;
    }

    if (updateInput) {
      searchController.text = trimmedSearchId;
    }
    await viewModel.searchUser(trimmedSearchId);
    if (!mounted || viewModel.message == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(viewModel.message!)),
    );
  }

  Future<void> _showSearchIdQr(String searchId) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final screenSize = MediaQuery.sizeOf(context);
        final qrSize = [
          280.0,
          screenSize.width - 96.0,
          screenSize.height - 192.0,
        ].reduce((value, element) => value < element ? value : element);

        return AlertDialog(
          content: SizedBox.square(
            dimension: qrSize,
            child: QrImageView(
              data: searchId,
              version: QrVersions.auto,
              backgroundColor: Colors.white,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareFriendInvite({
    required String inviterName,
  }) async {
    if (_isSharingInvite) {
      return;
    }

    setState(() {
      _isSharingInvite = true;
    });
    try {
      final inviteUrl =
          await ref.read(friendInviteLinkServiceProvider).createInviteLink();
      if (!mounted) {
        return;
      }

      final content = FriendInviteShareContent.create(
        inviteUrl: inviteUrl,
        inviterName: inviterName,
      );
      final renderBox = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = renderBox == null
          ? null
          : renderBox.localToGlobal(Offset.zero) & renderBox.size;

      await SharePlus.instance.share(
        ShareParams(
          text: content.message,
          subject: 'LaKiiteに招待',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } on FriendInviteLinkException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('招待リンクの生成に失敗しました')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharingInvite = false;
        });
      }
    }
  }

  Widget _buildDisabledRequestButton(String label) {
    return ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey,
      ),
      child: Text(label),
    );
  }

  Future<void> _openQrScanner(FriendSearchViewModel viewModel) async {
    final scannedSearchId = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const FriendSearchQrScannerPage(),
      ),
    );

    if (!mounted || scannedSearchId == null) {
      return;
    }

    _searchById(scannedSearchId, viewModel, updateInput: false);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(friendSearchViewModelProvider.notifier);
    final state = ref.watch(friendSearchViewModelProvider);
    final currentUser = ref.watch(auth.authNotifierProvider).value?.user;
    final currentSearchId = currentUser?.searchId.toString();
    final currentDisplayName = currentUser?.displayName;
    final qrButtonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      textStyle: Theme.of(context).textTheme.titleSmall,
      iconSize: 24,
    );
    final inviteButtonStyle = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(58),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      textStyle: Theme.of(context).textTheme.titleSmall,
      iconSize: 24,
    );

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
            TextField(
              controller: searchController,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: '検索IDを入力',
                labelStyle: Theme.of(context).textTheme.bodyLarge,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _searchById(searchController.text, viewModel);
                  },
                ),
              ),
              onSubmitted: (value) => _searchById(value, viewModel),
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: qrButtonStyle,
                    onPressed: currentSearchId == null
                        ? null
                        : () => _showSearchIdQr(currentSearchId),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('自分のQR'),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: qrButtonStyle,
                    onPressed: () => _openQrScanner(viewModel),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('QRを読み取る'),
                  ),
                ),
              ],
            ),
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: inviteButtonStyle,
                onPressed: currentSearchId == null || _isSharingInvite
                    ? null
                    : () => _shareFriendInvite(
                          inviterName: currentDisplayName ?? '',
                        ),
                icon: _isSharingInvite
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share),
                label: Text(_isSharingInvite ? '招待リンクを作成中' : '友人をアプリに招待する'),
              ),
            ),
            const Gap(8),
            Text(
              'アプリをまだ使っていない人にも、すでに使っている人にも、フレンド追加の招待を送れます。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                    height: 1.45,
                  ),
            ),
            const Gap(20),
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
                        onPopInvokedWithResult: (didPop, result) {
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
                                CircleAvatar(
                                  radius: 40,
                                  backgroundImage:
                                      state.value!.iconUrl.isNotEmpty
                                          ? NetworkImage(state.value!.iconUrl)
                                          : null,
                                  child: state.value!.iconUrl.isEmpty
                                      ? const Icon(Icons.person, size: 40)
                                      : null,
                                ),
                                const Gap(16),
                                Text(
                                  state.value!.displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Gap(8),
                                if (state.value!.shortBio != null &&
                                    state.value!.shortBio!.isNotEmpty)
                                  Text(
                                    state.value!.shortBio!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const Gap(24),
                                if (state.value!.isFriend)
                                  _buildDisabledRequestButton('追加済み')
                                else if (state.value!.hasPendingRequest)
                                  _buildDisabledRequestButton('申請済み')
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
                return const Offstage();
              },
            ),
          ],
        ),
      ),
    );
  }
}
