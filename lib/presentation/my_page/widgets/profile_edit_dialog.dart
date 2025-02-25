import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entity/user.dart';
import '../my_page_view_model.dart';

/// プロフィール編集用のダイアログウィジェット
///
/// [user] 編集対象のユーザーモデル
/// [onImageEdit] プロフィール画像編集時のコールバック
class ProfileEditDialog extends ConsumerStatefulWidget {
  final UserModel user;
  final VoidCallback onImageEdit;

  const ProfileEditDialog({
    super.key,
    required this.user,
    required this.onImageEdit,
  });

  @override
  ConsumerState<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

/// プロフィール編集ダイアログの状態を管理するクラス
class _ProfileEditDialogState extends ConsumerState<ProfileEditDialog> {
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

                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

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
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('プロフィールを更新しました')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
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
