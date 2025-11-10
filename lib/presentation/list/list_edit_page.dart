import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/entity/list.dart';
import '../../domain/entity/user.dart';
import '../presentation_provider.dart';

class ListEditPage extends ConsumerStatefulWidget {
  final UserList list;

  const ListEditPage({super.key, required this.list});

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

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('リスト名を入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String? newIconUrl = widget.list.iconUrl;
      if (_selectedImage != null) {
        // 画像のアップロード処理を実装
        // newIconUrl = await uploadImage(_selectedImage!);
      }

      // メンバーリストの更新
      final updatedMemberIds = widget.list.memberIds
          .where((id) => !_excludedMemberIds.contains(id))
          .toList();

      // 更新されたリストオブジェクトを作成
      final updatedList = UserList(
        id: widget.list.id,
        listName: _nameController.text.trim(),
        ownerId: widget.list.ownerId,
        memberIds: updatedMemberIds,
        createdAt: widget.list.createdAt,
        iconUrl: newIconUrl,
        description: widget.list.description,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('リストを編集'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: FilledButton(
                onPressed: _saveChanges,
                child: const Text('保存'),
              ),
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
                          : (widget.list.iconUrl != null
                              ? NetworkImage(widget.list.iconUrl!)
                              : null) as ImageProvider?,
                      child:
                          _selectedImage == null && widget.list.iconUrl == null
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
                    itemCount: widget.list.memberIds.length,
                    itemBuilder: (context, index) {
                      final memberId = widget.list.memberIds[index];
                      return FutureBuilder<PublicUserModel?>(
                        future: ref
                            .read(userRepositoryProvider)
                            .getFriendPublicProfile(memberId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Card(
                              child: ListTile(
                                leading: CircularProgressIndicator(),
                                title: Text('読み込み中...'),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.error),
                                title: Text('エラーが発生しました: ${snapshot.error}'),
                              ),
                            );
                          }

                          final member = snapshot.data;
                          if (member == null) {
                            return const SizedBox.shrink();
                          }

                          final isExcluded =
                              _excludedMemberIds.contains(memberId);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isExcluded ? Colors.grey.shade200 : null,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  if (isExcluded) {
                                    _excludedMemberIds.remove(memberId);
                                  } else {
                                    _excludedMemberIds.add(memberId);
                                  }
                                });
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: member.iconUrl != null
                                      ? NetworkImage(member.iconUrl!)
                                      : null,
                                  child: member.iconUrl == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(
                                  member.displayName,
                                  style: isExcluded
                                      ? const TextStyle(color: Colors.grey)
                                      : null,
                                ),
                                subtitle: member.shortBio != null &&
                                        member.shortBio!.isNotEmpty
                                    ? Text(
                                        member.shortBio!,
                                        style: isExcluded
                                            ? TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              )
                                            : TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : null,
                                trailing: Checkbox(
                                  value: isExcluded,
                                  onChanged: (value) {
                                    setState(() {
                                      if (value == true) {
                                        _excludedMemberIds.add(memberId);
                                      } else {
                                        _excludedMemberIds.remove(memberId);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                          );
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
