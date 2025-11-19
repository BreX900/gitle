import 'package:flutter/material.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class PushDialog extends SourceConsumerStatefulWidget with TypedWidgetMixin<void> {
  final GitDir gitDir;
  final String branchName;

  const PushDialog({super.key, required this.gitDir, required this.branchName});

  @override
  SourceConsumerState<PushDialog> createState() => _PushDialogState();
}

class _PushDialogState extends SourceConsumerState<PushDialog> {
  final _pushWithUpstreamFb = FormControlTyped<bool>(initialValue: false);
  final _pushForceFb = FormControlTypedOptional<PushForce>();

  late final _form = FormArray<void>([_pushWithUpstreamFb, _pushForceFb]);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  late final _pushMutation = ref.mutationV2((ref, None _) async {
    await GitProviders.push(
      ref,
      gitDir: widget.gitDir,
      force: _pushForceFb.value,
      upstream: _pushWithUpstreamFb.value ? widget.branchName : null,
    );
  });

  void _push() {
    _form.markAsDisabled();
    _pushMutation(
      none,
      onError: (error) {
        _form.markAsEnabled();
        AppUtils.showErrorSnackBar(context, error);
      },
      onSuccess: (_) => context.nav.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watchIsMutating([_pushMutation]);
    final isFormDirty = ref.watchSource(_form.source.dirty);
    final push = _form.handleSubmit(_push);

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
            ReactiveFormField<PushForce, PushForce>(
              formControl: _pushForceFb,
              builder: (field) => RadioGroup<PushForce>(
                groupValue: field.value,
                onChanged: field.didChange,
                child: Column(
                  children: PushForce.values.map((value) {
                    return RadioListTile(
                      enabled: field.control.enabled,
                      toggleable: true,
                      value: value,
                      title: Text(value.translate()),
                    );
                  }).toList(),
                ),
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
        ElevatedButton(onPressed: isIdle && isFormDirty ? push : null, child: const Text('Push')),
      ],
    );
  }
}
