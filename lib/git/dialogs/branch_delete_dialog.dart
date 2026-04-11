import 'package:flutter/material.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/git/git_providers.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class BranchDeleteDialog extends SourceConsumerStatefulWidget with TypedWidgetMixin<void> {
  final GitDir gitDir;
  final String branchName;

  const BranchDeleteDialog({super.key, required this.gitDir, required this.branchName});

  @override
  SourceConsumerState<BranchDeleteDialog> createState() => _BranchDeleteDialogState();
}

class _BranchDeleteDialogState extends SourceConsumerState<BranchDeleteDialog> {
  final _forceFb = FormControlTyped(initialValue: false);
  final _remotesFb = FormControlTyped(initialValue: false);

  late final _form = FormArray([_remotesFb, _forceFb]);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  late final _deleteBranchMutation = ref.mutationV2((ref, None _) {
    return GitProviders.deleteBranch(
      ref,
      gitDir: widget.gitDir,
      branchName: widget.branchName,
      force: _forceFb.value,
      remote: _remotesFb.value,
    );
  });

  void _deleteBranch() {
    _form.markAsDisabled();
    _deleteBranchMutation(
      none,
      onError: (error) {
        _form.markAsEnabled();
        AppUtils.showErrorSnackBar(context, error);
      },
      onSuccess: (__) => context.nav.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watchIsMutating([_deleteBranchMutation]);
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
            ReactiveSwitchListTile(formControl: _forceFb, title: const Text('Force Delete')),
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
        ElevatedButton(onPressed: isIdle ? deleteBranch : null, child: const Text('Delete')),
      ],
    );
  }
}
