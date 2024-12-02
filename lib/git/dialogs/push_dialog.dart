import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

enum _PushType {
  setUpstream,
  forceWithLease,
  force;

  String translate() {
    switch (this) {
      case _PushType.setUpstream:
        return 'Push with upstream';
      case _PushType.forceWithLease:
        return 'Force Push With Lease';
      case _PushType.force:
        return 'Force Push';
    }
  }

  PushForce? toForce() {
    switch (this) {
      case _PushType.setUpstream:
        return null;
      case _PushType.forceWithLease:
        return PushForce.enabledWithLease;
      case _PushType.force:
        return PushForce.enabled;
    }
  }
}

class PushDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final GitDir gitDir;
  final String branchName;

  const PushDialog({
    super.key,
    required this.gitDir,
    required this.branchName,
  });

  @override
  ConsumerState<PushDialog> createState() => _PushDialogState();
}

class _PushDialogState extends ConsumerState<PushDialog> {
  late final _push = ref.mutation((ref, Nil _) async {
    await GitProviders.push(
      ref,
      gitDir: widget.gitDir,
      force: _pushForceFb.value?.toForce(),
      upstream: _pushForceFb.value == _PushType.setUpstream ? widget.branchName : null,
    );
  }, onSuccess: (_, __) {
    context.nav.pop();
  });

  final _pushForceFb = FormControlTypedOptional<_PushType>();

  late final _form = FormArray([_pushForceFb]);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watchIsMutating([_push]);
    final isFormDirty = ref.watch(_form.provider.dirty);
    final push = _form.handleSubmit(_push);

    return AlertDialog(
      title: Text('Push ${widget.branchName}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 384.0, minHeight: 192.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReactiveFormField(
              formControl: _pushForceFb,
              builder: (field) => Column(
                children: _PushType.values.map((value) {
                  final isEnabled = field.control.enabled;

                  return RadioListTile(
                    groupValue: field.value,
                    toggleable: true,
                    value: value,
                    onChanged: isEnabled ? field.didChange : null,
                    title: Text(value.translate()),
                  );
                }).toList(),
              ),
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
          onPressed: isIdle && isFormDirty ? () => push(nil) : null,
          child: const Text('Push'),
        ),
      ],
    );
  }
}
