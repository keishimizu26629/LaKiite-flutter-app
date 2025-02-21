import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation_provider.dart';
import 'my_page_view_model.dart';
import '../calendar/schedule_detail_page.dart';
import 'package:intl/intl.dart';
import '../../domain/entity/user.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/ad_banner_widget.dart';

class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

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

  Widget _buildScheduleList(String userId) {
    final schedulesAsync = ref.watch(userSchedulesStreamProvider(userId));

    return schedulesAsync.when(
      data: (schedules) {
        // 自分の予定のみをフィルタリング
        final mySchedules =
            schedules.where((s) => s.ownerId == userId).toList();

        if (mySchedules.isEmpty) {
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

        // 日付でソート
        mySchedules.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: mySchedules.length,
          itemBuilder: (context, index) {
            final schedule = mySchedules[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ScheduleDetailPage(schedule: schedule),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).primaryColor.withOpacity(0.05),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              schedule.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: () {
                              context.push('/calendar/create', extra: schedule);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (schedule.description.isNotEmpty) ...[
                        Text(
                          schedule.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${DateFormat('yyyy/MM/dd HH:mm').format(schedule.startDateTime)} - '
                              '${DateFormat('yyyy/MM/dd HH:mm').format(schedule.endDateTime)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (schedule.location != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                schedule.location!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${schedule.reactionCount}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.comment,
                            size: 16,
                            color: Colors.blue[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${schedule.commentCount}',
                            style: TextStyle(
                              color: Colors.blue[400],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
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
    );
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
                            Card(
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 40,
                                      backgroundColor: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
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
                                          const SizedBox(height: 4),
                                          GestureDetector(
                                            onTap: () async {
                                              await Clipboard.setData(
                                                ClipboardData(
                                                    text: user.searchId
                                                        .toString()),
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
                                                const Icon(
                                                  Icons.copy,
                                                  size: 14,
                                                  color: AppTheme.primaryColor,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          OutlinedButton.icon(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder: (dialogContext) =>
                                                    _ProfileEditDialog(
                                                  user: user,
                                                  onImageEdit: () async {
                                                    if (!mounted) return;

                                                    try {
                                                      await ref
                                                          .read(
                                                              myPageViewModelProvider
                                                                  .notifier)
                                                          .pickImage();
                                                    } catch (e) {
                                                      if (mounted) {
                                                        ScaffoldMessenger.of(
                                                                dialogContext)
                                                            .showSnackBar(
                                                          SnackBar(
                                                              content: Text(
                                                                  '画像の選択に失敗しました: $e')),
                                                        );
                                                      }
                                                    }
                                                  },
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Theme.of(context)
                                                  .primaryColor,
                                              side: BorderSide(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                            ),
                                            icon: const Icon(Icons.edit),
                                            label: const Text('プロフィールを編集'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Icon(
                                  Icons.description_outlined,
                                  size: 24,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '一言コメント',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
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
                                  user.publicProfile.shortBio?.trim() ?? '',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 24,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '予定一覧',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildScheduleList(user.id),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
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
                  ),
                ),
              ),
            ),
            const AdBannerWidget(),
          ],
        ),
      ),
    );
  }
}

class _ProfileEditDialog extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback onImageEdit;

  const _ProfileEditDialog({
    required this.user,
    required this.onImageEdit,
  });

  @override
  ConsumerState<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends ConsumerState<_ProfileEditDialog> {
  late TextEditingController _displayNameController;
  late TextEditingController _shortBioController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _displayNameController =
        TextEditingController(text: widget.user.displayName);
    _shortBioController =
        TextEditingController(text: widget.user.publicProfile.shortBio ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _shortBioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('プロフィール編集'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _isProcessing ? null : widget.onImageEdit,
            child: Builder(
              builder: (context) {
                final selectedImage = ref.watch(selectedImageProvider);
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage)
                          : (widget.user.iconUrl != null
                              ? NetworkImage(widget.user.iconUrl!)
                                  as ImageProvider<Object>
                              : null),
                      child:
                          widget.user.iconUrl == null && selectedImage == null
                              ? const Icon(Icons.person,
                                  size: 40, color: Colors.grey)
                              : null,
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _displayNameController,
            enabled: !_isProcessing,
            decoration: const InputDecoration(
              labelText: '表示名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            width: double.infinity,
            child: TextField(
              controller: _shortBioController,
              enabled: !_isProcessing,
              decoration: InputDecoration(
                labelText: '一言コメント',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                floatingLabelStyle: TextStyle(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              maxLines: 3,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isProcessing
              ? null
              : () {
                  ref.read(selectedImageProvider.notifier).state = null;
                  Navigator.pop(context);
                },
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _isProcessing
              ? null
              : () async {
                  setState(() {
                    _isProcessing = true;
                  });
                  try {
                    final selectedImage = ref.read(selectedImageProvider);
                    await ref
                        .read(myPageViewModelProvider.notifier)
                        .updateProfile(
                          name: widget.user.name,
                          displayName: _displayNameController.text,
                          searchIdStr: widget.user.searchId.toString(),
                          shortBio: _shortBioController.text,
                          imageFile: selectedImage,
                        );
                    ref.read(selectedImageProvider.notifier).state = null;
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('プロフィールを更新しました')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('エラー: ${e.toString()}')),
                      );
                      setState(() {
                        _isProcessing = false;
                      });
                    }
                  }
                },
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('保存'),
        ),
      ],
    );
  }
}
