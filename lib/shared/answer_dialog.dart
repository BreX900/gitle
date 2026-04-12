import 'package:flutter/material.dart';

class AnswerDialog extends StatelessWidget {
  final Widget title;
  final Widget content;

  const AnswerDialog({super.key, required this.title, required this.content});

  const AnswerDialog.delete({super.key, required this.content}) : title = const Text('Delete?');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: content,
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
      ],
    );
  }
}
