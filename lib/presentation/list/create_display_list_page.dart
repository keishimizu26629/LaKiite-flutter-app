import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lakiite/app/di/providers.dart';
import 'package:lakiite/application/auth/auth_notifier.dart';
import 'package:lakiite/application/auth/auth_state.dart';
import 'package:lakiite/presentation/list/display_list_palette.dart';

class CreateDisplayListPage extends ConsumerStatefulWidget {
  const CreateDisplayListPage({super.key});

  @override
  ConsumerState<CreateDisplayListPage> createState() =>
      _CreateDisplayListPageState();
}

class _CreateDisplayListPageState extends ConsumerState<CreateDisplayListPage> {
  final _nameController = TextEditingController();
  String _selectedColorKey = DisplayListPalette.defaultColorKey;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final authState = ref.read(authNotifierProvider).valueOrNull;
    final user = authState?.user;
    if (authState?.status != AuthStatus.authenticated || user == null) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('リスト名を入力してください')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(displayListRepositoryProvider).createDisplayList(
        ownerId: user.id,
        name: name,
        colorKey: _selectedColorKey,
        memberIds: const [],
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('表示用リストの作成に失敗しました: $e')),
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
      appBar: AppBar(title: const Text('表示用リストを作成')),
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
            _ColorPaletteSelector(
              selectedColorKey: _selectedColorKey,
              onChanged: (colorKey) {
                setState(() => _selectedColorKey = colorKey);
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _save,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.save),
        label: const Text('保存'),
      ),
    );
  }
}

class _ColorPaletteSelector extends StatelessWidget {
  const _ColorPaletteSelector({
    required this.selectedColorKey,
    required this.onChanged,
  });

  final String selectedColorKey;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: DisplayListPalette.entries.map((entry) {
        final selected = entry.key == selectedColorKey;
        return Semantics(
          label: '${entry.label}を選択',
          selected: selected,
          button: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => onChanged(entry.key),
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
    );
  }
}
