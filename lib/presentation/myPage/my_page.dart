import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers.dart';
import 'my_page_view_model.dart';

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
      final userId = ref.read(authNotifierProvider).user?.uid;
      if (userId != null) {
        ref.read(myPageViewModelProvider.notifier).loadUser(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(myPageViewModelProvider);
    final isEditing = ref.watch(myPageEditingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('マイページ'),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => ref.read(myPageEditingProvider.notifier).state = true,
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => ref.read(myPageEditingProvider.notifier).state = false,
            ),
        ],
      ),
      body: userState.when(
        data: (user) {
          if (user == null) return const Center(child: Text('ユーザー情報が見つかりません'));

          final nameController = TextEditingController(text: user.name);
          final displayNameController = TextEditingController(text: user.displayName);
          final searchIdController = TextEditingController(text: user.searchId.toString());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        child: Builder(
                          builder: (context) {
                            final selectedImage = ref.watch(selectedImageProvider);
                            if (selectedImage != null) {
                              return ClipOval(
                                child: Image.file(
                                  selectedImage,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }
                            return user.iconUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      user.iconUrl!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.person, size: 50, color: Colors.grey);
                          },
                        ),
                      ),
                      if (isEditing)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final pickedFile = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              if (pickedFile != null) {
                                ref.read(selectedImageProvider.notifier).state = File(pickedFile.path);
                              }
                            },
                            child: Container(
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
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (!isEditing) ...[
                  _ProfileField(label: '名前', value: user.name),
                  _ProfileField(label: '表示名', value: user.displayName),
                  _ProfileField(label: '検索ID', value: user.searchId.toString()),
                ] else ...[
                  _ProfileTextField(
                    label: '名前',
                    controller: nameController,
                  ),
                  _ProfileTextField(
                    label: '表示名',
                    controller: displayNameController,
                  ),
                  _ProfileTextField(
                    label: '検索ID',
                    controller: searchIdController,
                    helperText: '8文字の半角英数字',
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final selectedImage = ref.read(selectedImageProvider);
                          await ref.read(myPageViewModelProvider.notifier).updateProfile(
                                name: nameController.text,
                                displayName: displayNameController.text,
                                searchIdStr: searchIdController.text,
                                imageFile: selectedImage,
                              );
                          ref.read(selectedImageProvider.notifier).state = null;
                          ref.read(myPageEditingProvider.notifier).state = false;
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('プロフィールを更新しました')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('エラー: ${e.toString()}')),
                            );
                          }
                        }
                      },
                      child: const Text('保存'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await ref.read(authNotifierProvider.notifier).signOut();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ログアウトに失敗しました')),
                          );
                        }
                      }
                    },
                    child: const Text('ログアウト'),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: ${error.toString()}')),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _ProfileTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? helperText;

  const _ProfileTextField({
    required this.label,
    required this.controller,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
