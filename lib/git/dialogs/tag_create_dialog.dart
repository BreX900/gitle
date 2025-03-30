import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/common/branch_utils.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:gitle/git/widgets/sha_text.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

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
  // final _typeFb = FieldBloc(initialValue: <_BranchType>{});
  final _nameFb = FormControlTyped<String>(
    initialValue: '',
    validators: [ValidatorsTyped.required()],
  );
  final _messageFb = FormControlTyped(initialValue: '');
  final _pushableToRemoteFb = FormControlTyped(disabled: true, initialValue: true);

  late final _form = FormArray([_nameFb, _messageFb, _pushableToRemoteFb]);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  late final _createTag = ref.mutation((ref, None _) async {
    await GitProviders.createTag(
      ref,
      gitDir: widget.gitDir,
      commitSha: widget.startPoint,
      name: _nameFb.value,
      message: _messageFb.value,
    );
  }, onError: (_, error) {
    AppUtils.showErrorSnackBar(context, error);
  }, onSuccess: (_, __) {
    context.nav.pop();
  });

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watchIsMutating([_createTag]);
    final createTag = _form.handleSubmit(_createTag.run, keepDisabled: true);

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
            ReactiveTextField(
              formControl: _nameFb,
              inputFormatters: [BranchUtils.textFormatter],
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            ReactiveTextField(
              formControl: _messageFb,
              minLines: 1,
              maxLines: 10,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            ReactiveSwitchListTile(
              formControl: _pushableToRemoteFb,
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
          onPressed: isIdle ? () => createTag(none) : null,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
