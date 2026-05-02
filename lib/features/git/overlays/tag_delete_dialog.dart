import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/git/git_providers.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class TagDeleteDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final GitDir gitDir;
  final String name;

  const TagDeleteDialog({super.key, required this.gitDir, required this.name});

  @override
  ConsumerState<TagDeleteDialog> createState() => _TagDeleteDialogState();
}

class _TagDeleteDialogState extends ConsumerState<TagDeleteDialog> {
  late final _mutation = MutationController(ref);

  final _remotesFb = FormControlTyped(initialValue: false);

  late final _form = FormArray([_remotesFb]);

  @override
  void dispose() {
    _form.dispose();
    _mutation.dispose();
    super.dispose();
  }

  void _deleteTag() {
    _mutation(
      (ref) async => await GitProviders.deleteTag(
        ref,
        gitDir: widget.gitDir,
        name: widget.name,
        remote: _remotesFb.value,
      ),
      onError: (error, stackTrace) => AppUtils.showErrorSnackBar(context, error),
      onSuccess: (_) => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watch(_mutation.provider.isPending);
    final deleteTag = _form.handleSubmit(_deleteTag);

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
        ElevatedButton(onPressed: isIdle ? deleteTag : null, child: const Text('Delete')),
      ],
    );
  }
}
