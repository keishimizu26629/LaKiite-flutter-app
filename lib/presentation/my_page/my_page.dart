import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../presentation_provider.dart';
import 'my_page_view_model.dart';
import '../../domain/entity/user.dart';
import '../widgets/schedule_card.dart';

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
        if (schedules.isEmpty) {
          return const Center(
            child: Text('予定はありません'),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: schedules.length,
          itemBuilder: (context, index) {
            final schedule = schedules[index];
            return ScheduleCard(
              schedule: schedule,
              isOwner: schedule.ownerId == userId,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: ${error.toString()}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(myPageViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push('/settings');
            },
          ),
        ],
      ),
      body: userState.when(
        data: (user) {
          if (user == null) return const Center(child: Text('ユーザー情報が見つかりません'));

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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        child: Builder(
                          builder: (context) {
                            final selectedImage =
                                ref.watch(selectedImageProvider);
                            if (selectedImage != null) {
                              return ClipOval(
                                child: Image.file(
                                  selectedImage,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }
                            return user.iconUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      user.iconUrl!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.person,
                                    size: 40, color: Colors.grey);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                // プロフィール編集ダイアログを表示
                                showDialog(
                                  context: context,
                                  builder: (context) => _ProfileEditDialog(
                                    user: user,
                                    onImageEdit: () async {
                                      final picker = ImagePicker();
                                      final pickedFile = await picker.pickImage(
                                        source: ImageSource.gallery,
                                      );
                                      if (pickedFile != null) {
                                        ref
                                            .read(
                                                selectedImageProvider.notifier)
                                            .state = File(pickedFile.path);
                                        try {
                                          await ref
                                              .read(myPageViewModelProvider
                                                  .notifier)
                                              .updateProfile(
                                                name: user.name,
                                                displayName: user.displayName,
                                                searchIdStr:
                                                    user.searchId.toString(),
                                                shortBio:
                                                    user.publicProfile.shortBio,
                                                imageFile:
                                                    File(pickedFile.path),
                                              );
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                  content:
                                                      Text('プロフィール画像を更新しました')),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'エラー: ${e.toString()}')),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('プロフィールを編集'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '一言コメント',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.publicProfile.shortBio ?? '',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '予定一覧',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildScheduleList(user.id),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            Center(child: Text('エラー: ${error.toString()}')),
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
            onTap: widget.onImageEdit,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: widget.user.iconUrl != null
                      ? NetworkImage(widget.user.iconUrl!)
                      : null,
                  child: widget.user.iconUrl == null
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
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
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: '表示名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _shortBioController,
            decoration: const InputDecoration(
              labelText: '一言コメント',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(myPageViewModelProvider.notifier).updateProfile(
                    name: widget.user.name,
                    displayName: _displayNameController.text,
                    searchIdStr: widget.user.searchId.toString(),
                    shortBio: _shortBioController.text,
                  );
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
              }
            }
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
