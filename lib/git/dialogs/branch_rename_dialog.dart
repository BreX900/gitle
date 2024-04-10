import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/branch_utils.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:mek/mek.dart';

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
  late final _renameBranch = ref.mutation(GitProviders.renameBranch, onSuccess: (_, __) {
    context.nav.pop();
  });

  final _typeFb = FieldBloc<BranchType?>(initialValue: null);
  final _newNameFb = FieldBloc(
    initialValue: '',
    validator: const TextValidation(minLength: 3),
  );

  late final _form = ListFieldBloc(fieldBlocs: [_typeFb, _newNameFb]);

  @override
  void initState() {
    super.initState();
    final values = BranchType.from(widget.branchName);
    _typeFb.updateInitialValue(values.$1);
    _newNameFb.updateInitialValue(values.$2);
  }

  @override
  void dispose() {
    unawaited(_form.close());
    super.dispose();
  }

  String _resolveBranchName() => _typeFb.state.value.toName(_newNameFb.state.value);

  @override
  Widget build(BuildContext context) {
    final isIdle = ref.watchIdle(mutations: [_renameBranch]);
    final canSubmit = ref.watchCanSubmit(_form);

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
            FieldSegmentedButton(
              fieldBloc: _typeFb,
              emptySelectionAllowed: true,
              converter: _typeFb.transform(const SetFieldConverter<BranchType>()),
              segments: BranchType.values.map((type) {
                return ButtonSegment(
                  value: type,
                  label: Text(type.name),
                );
              }).toList(),
            ),
            FieldText(
              fieldBloc: _newNameFb,
              converter: FieldConvert.text,
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
          onPressed: isIdle && canSubmit
              ? () => _renameBranch((
                    gitDir: widget.gitDir,
                    currentName: widget.branchName,
                    newName: _resolveBranchName(),
                  ))
              : null,
          child: const Text('Rename'),
        ),
      ],
    );
  }
}
