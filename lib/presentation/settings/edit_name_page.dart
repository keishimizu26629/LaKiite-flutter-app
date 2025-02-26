import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../my_page/my_page_view_model.dart';

class EditNamePage extends ConsumerStatefulWidget {
  const EditNamePage({super.key});

  @override
  ConsumerState<EditNamePage> createState() => _EditNamePageState();
}

class _EditNamePageState extends ConsumerState<EditNamePage> {
  late TextEditingController _nameController;
  late TextEditingController _displayNameController;

  @override
  void initState() {
    super.initState();
    final user = ref.read(myPageViewModelProvider).value;
    if (user != null) {
      _nameController = TextEditingController(text: user.name);
      _displayNameController = TextEditingController(text: user.displayName);
    } else {
      _nameController = TextEditingController();
      _displayNameController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(myPageViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('名前の設定'),
        actions: [
          TextButton(
            onPressed: () async {
              if (!userState.hasValue || userState.value == null) return;

              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                final user = userState.value!;
                final navigator = Navigator.of(context);
                await ref.read(myPageViewModelProvider.notifier).updateProfile(
                      name: _nameController.text,
                      displayName: _displayNameController.text,
                      searchIdStr: user.searchId.toString(),
                      shortBio: user.publicProfile.shortBio,
                    );
                if (mounted) {
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('名前を更新しました')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('エラー: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
      body: userState.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('ユーザー情報が見つかりません'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '名前（フルネーム）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '例：山田太郎',
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '表示名（ニックネーム）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: '例：やまちゃん',
                    helperText: '他のユーザーに表示される名前です',
                  ),
                ),
              ],
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
