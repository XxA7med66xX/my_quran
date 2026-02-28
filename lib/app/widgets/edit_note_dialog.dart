import 'package:flutter/material.dart';

enum NoteDialogAction { save, delete }

class NoteDialogResult {
  const NoteDialogResult(this.action, {this.text});
  final NoteDialogAction action;
  final String? text;
}

/// - If user cancels => returns null
/// - If user saves => returns NoteDialogResult(save, text: ...)
/// - If user deletes (only if canDelete) => returns NoteDialogResult(delete)
Future<NoteDialogResult?> showEditNoteDialog(
  BuildContext context, {
  String initialText = '',
  bool canDelete = false,
}) async {
  final controller = TextEditingController(text: initialText);

  return showDialog<NoteDialogResult>(
    context: context,
    builder: (ctx) {
      final colorScheme = Theme.of(ctx).colorScheme;

      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ملاحظة'),
              if (canDelete)
                TextButton(
                  onPressed: () => Navigator.pop(
                    ctx,
                    const NoteDialogResult(NoteDialogAction.delete),
                  ),
                  child: Text(
                    'حذف',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
            ],
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'اكتب ملاحظتك هنا...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  // treat empty as cancel for new note, or delete for existing
                  if (canDelete) {
                    Navigator.pop(
                      ctx,
                      const NoteDialogResult(NoteDialogAction.delete),
                    );
                  } else {
                    Navigator.pop(ctx);
                  }
                  return;
                }
                Navigator.pop(
                  ctx,
                  NoteDialogResult(NoteDialogAction.save, text: text),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      );
    },
  );
}
