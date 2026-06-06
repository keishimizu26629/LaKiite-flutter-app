import 'package:flutter/material.dart';

class ListEditSaveAction extends StatelessWidget {
  const ListEditSaveAction({
    super.key,
    required this.isSaving,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: isSaving
          ? const Center(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : FilledButton(
              onPressed: onSave,
              child: const Text('保存'),
            ),
    );
  }
}
