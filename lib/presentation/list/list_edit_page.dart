import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../application/list/list_notifier.dart';
import '../../domain/entity/list.dart';
import 'list_edit_save_action.dart';
import 'list_member_profile_tile.dart';
import 'list_providers.dart';

class ListEditPage extends ConsumerStatefulWidget {
  const ListEditPage({super.key, required this.list});
  final UserList list;

  @override
  ConsumerState<ListEditPage> createState() => _ListEditPageState();
}

class _ListEditPageState extends ConsumerState<ListEditPage> {
  late TextEditingController _nameController;
  File? _selectedImage;
  final Set<String> _excludedMemberIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.list.listName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _saveChanges(UserList currentList) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('リスト名を入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String? newIconUrl = currentList.iconUrl;
      if (_selectedImage != null) {
        // 画像のアップロード処理を実装
        // newIconUrl = await uploadImage(_selectedImage!);
      }

      // メンバーリストの更新
      final updatedMemberIds = currentList.memberIds
          .where((id) => !_excludedMemberIds.contains(id))
          .toList();

      // 更新されたリストオブジェクトを作成
      final updatedList = UserList(
        id: currentList.id,
        listName: _nameController.text.trim(),
        ownerId: currentList.ownerId,
        memberIds: updatedMemberIds,
        createdAt: currentList.createdAt,
        iconUrl: newIconUrl,
        description: currentList.description,
      );

      // リストの更新
      await ref.read(listNotifierProvider.notifier).updateList(updatedList);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新に失敗しました: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listAsync = ref.watch(listStreamProvider(widget.list.id));
    final currentList = listAsync.valueOrNull ?? widget.list;

    return Scaffold(
      appBar: AppBar(
        title: const Text('リストを編集'),
        actions: [
          ListEditSaveAction(
            isSaving: _isLoading,
            onSave: () => _saveChanges(currentList),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // アイコン選択部分
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : (currentList.iconUrl != null
                              ? NetworkImage(currentList.iconUrl!)
                              : null) as ImageProvider?,
                      child:
                          _selectedImage == null && currentList.iconUrl == null
                              ? const Icon(Icons.list, size: 50)
                              : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        backgroundColor: theme.primaryColor,
                        child: IconButton(
                          icon:
                              const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // リスト名入力
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'リスト名',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            // メンバー一覧
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '除外する友人を選択してください',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentList.memberIds.length,
                    itemBuilder: (context, index) {
                      final memberId = currentList.memberIds[index];
                      return EditableListMemberProfileTile(
                        memberId: memberId,
                        isExcluded: _excludedMemberIds.contains(memberId),
                        onChanged: (isExcluded) {
                          setState(() {
                            if (isExcluded) {
                              _excludedMemberIds.add(memberId);
                            } else {
                              _excludedMemberIds.remove(memberId);
                            }
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
