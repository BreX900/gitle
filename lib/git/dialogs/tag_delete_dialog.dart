import 'package:flutter/material.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class TagDeleteDialog extends SourceConsumerStatefulWidget with TypedWidgetMixin<void> {
  final GitDir gitDir;
  final String name;

  const TagDeleteDialog({super.key, required this.gitDir, required this.name});

  @override
  SourceConsumerState<TagDeleteDialog> createState() => _TagDeleteDialogState();
}

class _TagDeleteDialogState extends SourceConsumerState<TagDeleteDialog> {
  final _remotesFb = FormControlTyped(initialValue: false);

  late final _form = FormArray([_remotesFb]);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  late final _deleteBranchMutation = ref.mutationV2((ref, None _) {
    return GitProviders.deleteTag(
      ref,
      gitDir: widget.gitDir,
      name: widget.name,
      remote: _remotesFb.value,
    );
  });

  void _deleteBranch() {
    _deleteBranchMutation(
      none,
      onError: (error) => AppUtils.showErrorSnackBar(context, error),
      onSuccess: (_) => context.nav.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watchIsMutating([_deleteBranchMutation]);
    final deleteBranch = _form.handleSubmit(_deleteBranch);

    return AlertDialog(
      title: Text(
        'Are you sure you want to delete the this tag?\n${widget.name}',
        textAlign: TextAlign.center,
      ),
      contentPadding: const EdgeInsets.only(top: 20.0),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 384.0, minHeight: 192.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReactiveSwitchListTile(
              formControl: _remotesFb,
              title: const Text('Delete this tag on the remote'),
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
