import 'package:flutter/material.dart';
import 'package:lakiite/presentation/calendar/schedule_detail_logic.dart';

/// コメント編集用のDialog。
///
/// 入力UIと送信可否だけを扱い、実際の更新処理は呼び出し元へ委譲する。
class CommentEditDialog extends StatefulWidget {
  const CommentEditDialog({
    super.key,
    required this.initialContent,
    required this.onSave,
  });

  final String initialContent;
  final ValueChanged<String> onSave;

  @override
  State<CommentEditDialog> createState() => _CommentEditDialogState();
}

class _CommentEditDialogState extends State<CommentEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('コメントの編集'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'コメントを入力...'),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            final content = _controller.text;
            if (!ScheduleDetailLogic.canSubmitComment(content)) {
              return;
            }

            Navigator.of(context).pop();
            widget.onSave(content);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
