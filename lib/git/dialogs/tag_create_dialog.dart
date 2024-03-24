import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/branch_utils.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:gitle/git/widgets/sha_text.dart';
import 'package:mek/mek.dart';

class TagCreateDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final GitDir gitDir;
  final String startPoint;

  const TagCreateDialog({
    super.key,
    required this.gitDir,
    required this.startPoint,
  });

  @override
  ConsumerState<TagCreateDialog> createState() => _TagCreateDialogState();
}

class _TagCreateDialogState extends ConsumerState<TagCreateDialog> {
  late final _createTag = ref.mutation(GitProviders.createTag, onSuccess: (_, __) {
    context.nav.pop();
  });

  // final _typeFb = FieldBloc(initialValue: <_BranchType>{});
  final _nameFb = FieldBloc(initialValue: '');
  final _messageFb = FieldBloc(initialValue: '');
  final _pushableToRemoteFb = FieldBloc(isEnabled: false, initialValue: true);

  late final _form = ListFieldBloc(fieldBlocs: [_nameFb, _messageFb, _pushableToRemoteFb]);

  @override
  void dispose() {
    unawaited(_form.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = ref.watchIdle(mutations: [_createTag]);
    final canSubmit = ref.watchCanSubmit(_form);

    return AlertDialog(
      title: Row(
        children: [
          const Text('Add Tag to commit '),
          ShaText(widget.startPoint, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 384.0, minHeight: 192.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FieldText(
              fieldBloc: _nameFb,
              converter: FieldConvert.text,
              inputFormatters: [BranchUtils.textFormatter],
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            FieldText(
              fieldBloc: _messageFb,
              converter: FieldConvert.text,
              minLines: 1,
              maxLines: 10,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            FieldSwitchListTile(
              fieldBloc: _pushableToRemoteFb,
              title: const Text('Push to remote'),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isIdle ? () => Navigator.of(context).pop() : null,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isIdle && canSubmit
              ? () => _createTag((
                    gitDir: widget.gitDir,
                    commitSha: widget.startPoint,
                    name: _nameFb.state.value,
                    message: _messageFb.state.value
                  ))
              : null,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
