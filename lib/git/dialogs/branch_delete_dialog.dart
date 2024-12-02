import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class BranchDeleteDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final GitDir gitDir;
  final String branchName;

  const BranchDeleteDialog({
    super.key,
    required this.gitDir,
    required this.branchName,
  });

  @override
  ConsumerState<BranchDeleteDialog> createState() => _BranchDeleteDialogState();
}

class _BranchDeleteDialogState extends ConsumerState<BranchDeleteDialog> {
  final _forceFb = FormControlTyped(initialValue: false);
  final _remotesFb = FormControlTyped(initialValue: false);

  late final _form = FormArray([_remotesFb, _forceFb]);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  late final _deleteBranch = ref.mutation((ref, Nil _) {
    return GitProviders.deleteBranch(
      ref,
      gitDir: widget.gitDir,
      branchName: widget.branchName,
      force: _forceFb.value,
      remote: _remotesFb.value,
    );
  }, onSuccess: (_, __) {
    context.nav.pop();
  });

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watchIsMutating([_deleteBranch]);
    final deleteBranch = _form.handleSubmit(_deleteBranch);

    return AlertDialog(
      title: Text(
        'Are you sure you want to delete the this branch?\n${widget.branchName}',
        textAlign: TextAlign.center,
      ),
      contentPadding: const EdgeInsets.only(top: 20.0),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 384.0, minHeight: 192.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReactiveSwitchListTile(
              formControl: _forceFb,
              title: const Text('Force Delete'),
            ),
            ReactiveSwitchListTile(
              formControl: _remotesFb,
              title: const Text('Delete this branch on the remote'),
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
          onPressed: isIdle ? () => deleteBranch(nil) : null,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
