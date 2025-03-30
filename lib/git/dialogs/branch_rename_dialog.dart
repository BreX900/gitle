import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/common/branch_utils.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class BranchRenameDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final GitDir gitDir;
  final String branchName;

  const BranchRenameDialog({
    super.key,
    required this.gitDir,
    required this.branchName,
  });

  @override
  ConsumerState<BranchRenameDialog> createState() => _BranchRenameDialogState();
}

class _BranchRenameDialogState extends ConsumerState<BranchRenameDialog> {
  final _typeFb = FormControlTypedOptional<BranchType>();
  final _newNameFb = FormControlTyped<String>(
    initialValue: '',
    validators: [ValidatorsTyped.required()],
  );

  late final _form = FormArray<void>([_typeFb, _newNameFb]);

  @override
  void initState() {
    super.initState();
    final values = BranchType.from(widget.branchName);
    _typeFb.updateValue(values.$1);
    _newNameFb.updateValue(values.$2);
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  late final _renameBranch = ref.mutation((ref, None _) async {
    return await GitProviders.renameBranch(
      ref,
      gitDir: widget.gitDir,
      currentName: widget.branchName,
      newName: _resolveBranchName(),
    );
  }, onError: (_, error) {
    AppUtils.showErrorSnackBar(context, error);
  }, onSuccess: (_, __) {
    context.nav.pop();
  });

  String _resolveBranchName() => _typeFb.value.toName(_newNameFb.value);

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watchIsMutating([_renameBranch]);
    final isFormDirty = ref.watch(_form.provider.dirty);
    final renameBranch = _form.handleSubmit(_renameBranch.run);

    return AlertDialog(
      title: Row(
        children: [
          const Text('Enter the new name for branch '),
          Text(widget.branchName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text(':'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 384.0, minHeight: 192.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReactiveSegmentedButton(
              formControl: _typeFb,
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: BranchType.values.map((type) {
                return ButtonSegment(
                  value: type,
                  label: Text(type.name),
                );
              }).toList(),
            ),
            ReactiveTextField(
              formControl: _newNameFb,
              minLines: 1,
              maxLines: 10,
              inputFormatters: [BranchUtils.textFormatter],
              decoration: const InputDecoration(labelText: 'New Name'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isIdle ? () => Navigator.of(context).pop() : null,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isIdle && isFormDirty ? () => renameBranch(none) : null,
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
