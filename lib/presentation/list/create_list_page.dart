import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/auth/auth_state.dart';
import '../presentation_provider.dart';

/// プライベートリスト作成画面を表示するウィジェット
///
/// 機能:
/// - リスト名の入力
/// - リストの作成
///
/// 状態管理:
/// - Riverpodを使用
/// - ユーザーの認証状態に応じた処理
class CreateListPage extends ConsumerStatefulWidget {
  const CreateListPage({super.key});

  @override
  ConsumerState<CreateListPage> createState() => _CreateListPageState();
}

class _CreateListPageState extends ConsumerState<CreateListPage> {
  final _formKey = GlobalKey<FormState>();
  final _listNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _listNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createList() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authNotifierProvider).value;
      if (authState?.status == AuthStatus.authenticated &&
          authState?.user != null) {
        final description = _descriptionController.text.trim();

        await ref.read(listNotifierProvider.notifier).createList(
              listName: _listNameController.text,
              memberIds: [], // 作成者は初期メンバーとして追加しない
              ownerId: authState!.user!.id,
              iconUrl: null, // 初期値はnull
              description: description.isNotEmpty ? description : null,
            );
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('リストの作成に失敗しました: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('リストを作成'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _listNameController,
                      decoration: const InputDecoration(
                        labelText: 'リスト名',
                        hintText: 'リスト名を入力してください',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'リスト名を入力してください';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'リストの説明（任意）',
                        hintText: 'リストの説明を入力してください',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _createList,
                      child: const Text('作成'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
