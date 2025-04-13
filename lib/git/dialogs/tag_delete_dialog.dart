import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class TagDeleteDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final GitDir gitDir;
  final String name;

  const TagDeleteDialog({
    super.key,
    required this.gitDir,
    required this.name,
  });

  @override
  ConsumerState<TagDeleteDialog> createState() => _TagDeleteDialogState();
}

class _TagDeleteDialogState extends ConsumerState<TagDeleteDialog> {
  final _remotesFb = FormControlTyped(initialValue: false);

  late final _form = FormArray([_remotesFb]);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  late final _deleteBranch = ref.mutation((ref, None _) {
    return GitProviders.deleteTag(
      ref,
      gitDir: widget.gitDir,
      name: widget.name,
      remote: _remotesFb.value,
    );
  }, onError: (_, error) {
    AppUtils.showErrorSnackBar(context, error);
  }, onSuccess: (_, __) {
    context.nav.pop();
  });

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watchIsMutating([_deleteBranch]);
    final deleteBranch = _form.handleSubmit(_deleteBranch.run);

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
        ElevatedButton(
          onPressed: isIdle ? () => deleteBranch(none) : null,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
