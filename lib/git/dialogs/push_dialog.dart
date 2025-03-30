import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

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
  final _pushWithUpstreamFb = FormControlTyped<bool>(
    initialValue: false,
  );
  final _pushForceFb = FormControlTypedOptional<PushForce>();

  late final _form = FormArray([_pushForceFb]);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  late final _push = ref.mutation((ref, None _) async {
    await GitProviders.push(
      ref,
      gitDir: widget.gitDir,
      force: _pushForceFb.value,
      upstream: _pushWithUpstreamFb.value ? widget.branchName : null,
    );
  }, onError: (_, error) {
    AppUtils.showErrorSnackBar(context, error);
  }, onSuccess: (_, __) {
    context.nav.pop();
  });

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watchIsMutating([_push]);
    final isFormDirty = ref.watch(_form.provider.dirty);
    final push = _form.handleSubmit(_push.run);

    return AlertDialog(
      title: Text('Push ${widget.branchName}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 384.0, minHeight: 192.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReactiveSwitchListTile(
              formControl: _pushWithUpstreamFb,
              title: const Text('Push with upstream'),
            ),
            ReactiveFormField(
              formControl: _pushForceFb,
              builder: (field) => Column(
                children: PushForce.values.map((value) {
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
          onPressed: isIdle && isFormDirty ? () => push(none) : null,
          child: const Text('Push'),
        ),
      ],
    );
  }
}
