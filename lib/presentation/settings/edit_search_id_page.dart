import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../presentation_provider.dart';
import '../../domain/value/user_id.dart';
import '../my_page/my_page_view_model.dart';

class EditSearchIdPage extends ConsumerStatefulWidget {
  const EditSearchIdPage({super.key});

  @override
  ConsumerState<EditSearchIdPage> createState() => _EditSearchIdPageState();
}

class _EditSearchIdPageState extends ConsumerState<EditSearchIdPage> {
  late TextEditingController _searchIdController;
  String? _errorText;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(myPageViewModelProvider).value;
    if (user != null) {
      _searchIdController = TextEditingController(text: user.searchId.toString());
    } else {
      _searchIdController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _searchIdController.dispose();
    super.dispose();
  }

  Future<void> _validateSearchId(String value) async {
    if (value.isEmpty) {
      setState(() {
        _errorText = '検索IDを入力してください';
      });
      return;
    }

    try {
      UserId(value); // 形式チェック
    } catch (e) {
      setState(() {
        _errorText = '検索IDは8文字の半角英数字で入力してください';
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _errorText = null;
    });

    try {
      final user = ref.read(myPageViewModelProvider).value;
      if (user == null) return;

      // 現在の検索IDと同じ場合はチェック不要
      if (value == user.searchId.toString()) {
        setState(() {
          _isChecking = false;
          _errorText = null;
        });
        return;
      }

      final isUnique = await ref.read(userRepositoryProvider).isUserIdUnique(UserId(value));
      if (!isUnique) {
        setState(() {
          _errorText = 'この検索IDは既に使用されています';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = 'エラーが発生しました';
      });
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(myPageViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('検索IDの設定'),
        actions: [
          TextButton(
            onPressed: _errorText != null || _isChecking
                ? null
                : () async {
                    if (!userState.hasValue || userState.value == null) return;

                    try {
                      final user = userState.value!;
                      await ref.read(myPageViewModelProvider.notifier).updateProfile(
                            name: user.name,
                            displayName: user.displayName,
                            searchIdStr: _searchIdController.text,
                            shortBio: user.publicProfile.shortBio,
                          );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('検索IDを更新しました')),
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
                  '検索ID',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchIdController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: '例：user1234',
                    helperText: '8文字の半角英数字',
                    errorText: _errorText,
                    suffixIcon: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: _validateSearchId,
                ),
                const SizedBox(height: 16),
                const Text(
                  '検索IDは他のユーザーがあなたを見つけるために使用されます。\n一度設定すると変更できない場合がありますので、慎重に選んでください。',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
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
