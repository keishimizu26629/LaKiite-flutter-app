import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/group/group_notifier.dart';
import '../../application/auth/auth_notifier.dart';
import '../../application/auth/auth_state.dart';

/// グループ作成ページを表す `ConsumerStatefulWidget`。
///
/// このページでは、ユーザーが新しいグループを作成できます。
/// ユーザーが入力したグループ名を使用し、グループの所有者とメンバーとして
/// 現在のユーザーIDを設定してグループを作成します。
class CreateGroupPage extends ConsumerStatefulWidget {
  /// コンストラクタ。
  const CreateGroupPage({super.key});

  @override
  ConsumerState<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends ConsumerState<CreateGroupPage> {
  /// フォームの状態を管理するためのキー。
  final _formKey = GlobalKey<FormState>();

  /// グループ名入力フィールドのコントローラ。
  final _groupNameController = TextEditingController();

  /// ローディング中かどうかを示すフラグ。
  bool _isLoading = false;

  @override
  void dispose() {
    // リソースを解放するためにコントローラを破棄。
    _groupNameController.dispose();
    super.dispose();
  }

  /// グループを作成する非同期関数。
  ///
  /// フォームが有効である場合にのみ実行されます。
  /// 作成成功時には前の画面に戻り、失敗時にはエラーメッセージを表示します。
  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 認証状態が確定するまで待機
      final authState = await ref.read(authNotifierProvider.future);
      if (authState.status != AuthStatus.authenticated || authState.user == null) {
        throw Exception('ユーザーが見つかりません');
      }
      final userId = authState.user!.id;

      // グループ作成ロジックを実行。
      final groupNotifier = ref.read(groupNotifierProvider.notifier);
      await groupNotifier.createGroup(
        groupName: _groupNameController.text,
        memberIds: [userId],
        ownerId: userId,
      );

      // 作成成功時の処理。
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('グループを作成しました')),
        );
      }
    } catch (e) {
      // 作成失敗時のエラーメッセージ表示。
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('グループの作成に失敗しました: ${e.toString()}')),
        );
      }
    } finally {
      // ローディング状態を解除。
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
        title: const Text('グループを作成'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// グループ名を入力するためのフォームフィールド。
            TextFormField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: 'グループ名',
                hintText: 'グループ名を入力してください',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'グループ名を入力してください';
                }
                if (value.length > 50) {
                  return 'グループ名は50文字以内で入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            /// グループ作成ボタン。
            ElevatedButton(
              onPressed: _isLoading ? null : _createGroup,
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(),
                    )
                  : const Text('グループを作成'),
            ),
          ],
        ),
      ),
    );
  }
}
