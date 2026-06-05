import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/domain/entity/display_list.dart';
import 'package:lakiite/presentation/list/display_list_palette.dart';
import 'package:lakiite/presentation/list/list_edit_save_action.dart';

class DisplayListEditPage extends ConsumerStatefulWidget {
  const DisplayListEditPage({super.key, required this.displayList});

  final DisplayList displayList;

  @override
  ConsumerState<DisplayListEditPage> createState() =>
      _DisplayListEditPageState();
}

class _DisplayListEditPageState extends ConsumerState<DisplayListEditPage> {
  late final TextEditingController _nameController;
  late String _selectedColorKey;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.displayList.name);
    _selectedColorKey = widget.displayList.colorKey;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('リスト名を入力してください')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(displayListRepositoryProvider).updateDisplayList(
            widget.displayList.copyWith(
              name: name,
              colorKey: _selectedColorKey,
            ),
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('表示用リストの更新に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('表示用リストを編集'),
        actions: [
          ListEditSaveAction(
            isSaving: _isSaving,
            onSave: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'リスト名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'カラー',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: DisplayListPalette.entries.map((entry) {
                final selected = entry.key == _selectedColorKey;
                return Semantics(
                  label: '${entry.label}を選択',
                  selected: selected,
                  button: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => setState(() => _selectedColorKey = entry.key),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: entry.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.black87 : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
